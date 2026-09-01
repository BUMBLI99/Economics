# ============================================================
# imacec_models.R
# Especificaciones ganadoras fijadas por corte de información
# ============================================================

model_specs <- list(
  m4 = list(
    corte = "experimental",
    label = "M4 · Dinámico",
    formula = imacec ~ venta_minorista + monto_credito + cantidad_credito +
      imacec_lag1 + dias_habiles + efecto_bisiesto_yoy + mes_factor + dummy_covid
  ),
  m8p = list(
    corte = "ine",
    label = "M8P · INE + IVS real parsimonioso",
    formula = imacec ~ cantidad_credito + imacec_lag1 + avisos_laborales_lag1 +
      mineria + manufactura + comercio + electricidad + factor_ivs_real +
      dias_habiles + efecto_bisiesto_yoy + monto_credito_real + dummy_covid
  )
)

model_required_variables <- function(model_key, include_target = FALSE) {
  vars <- all.vars(model_specs[[model_key]]$formula)
  if (!include_target) vars <- setdiff(vars, "imacec")
  vars
}

latest_complete_period <- function(data, model_key) {
  required <- c("Periodo", model_required_variables(model_key))
  eligible <- data[stats::complete.cases(data[, required, drop = FALSE]), "Periodo"]
  if (!length(eligible)) stop("No existe un período completo para ", model_specs[[model_key]]$label, ".")
  max(eligible)
}

fit_winner <- function(data, model_key, target_period) {
  spec <- model_specs[[model_key]]
  train <- data |>
    dplyr::filter(Periodo < target_period) |>
    tidyr::drop_na(dplyr::all_of(c("imacec", model_required_variables(model_key))))

  if (nrow(train) < min_training_obs) {
    stop(spec$label, " tiene ", nrow(train), " observaciones; se requieren al menos ", min_training_obs, ".")
  }
  fit <- stats::lm(spec$formula, data = train)
  if (stats::df.residual(fit) < min_residual_df) {
    stop(spec$label, " tiene solo ", stats::df.residual(fit), " grados de libertad residuales.")
  }
  list(model = fit, train = train)
}

predict_interval <- function(model, newdata, level = interval_level) {
  pred <- as.data.frame(stats::predict(model, newdata = newdata, interval = "prediction", level = level))
  tibble::tibble(fit = pred$fit, lwr = pred$lwr, upr = pred$upr)
}

eee_for_period <- function(eee, period) {
  hit <- eee |>
    dplyr::filter(Periodo == period) |>
    dplyr::arrange(dplyr::desc(survey_period)) |>
    dplyr::slice_head(n = 1)
  if (nrow(hit)) hit else tibble::tibble(
    survey_period = as.Date(NA), Periodo = as.Date(period), eee_imacec = NA_real_
  )
}

run_nowcast <- function(model_key = c("m4", "m8p"), data = NULL, eee = NULL) {
  model_key <- match.arg(model_key)
  if (is.null(data)) data <- build_imacec_dataset()
  if (is.null(eee)) eee <- get_eee_expectations()

  target <- latest_complete_period(data, model_key)
  fitted <- fit_winner(data, model_key, target)
  newdata <- data |>
    dplyr::filter(Periodo == target) |>
    dplyr::slice_head(n = 1)
  prediction <- predict_interval(fitted$model, newdata)
  eee_target <- eee_for_period(eee, target)
  observed <- newdata$imacec[1]
  state <- if (is.na(observed)) "Nowcast activo" else "Pseudo-nowcast: dato oficial ya disponible"

  fit_history <- fitted$train |>
    dplyr::transmute(
      Periodo,
      imacec,
      imacec_fit = as.numeric(stats::predict(fitted$model)),
      model_key = model_key,
      modelo = model_specs[[model_key]]$label,
      corte = model_specs[[model_key]]$corte,
      tipo = "Ajuste"
    )

  projection <- tibble::tibble(
    Periodo = target,
    corte = model_specs[[model_key]]$corte,
    model_key = model_key,
    modelo = model_specs[[model_key]]$label,
    estado = state,
    imacec_predicho = prediction$fit,
    imacec_lwr = prediction$lwr,
    imacec_upr = prediction$upr,
    nivel_intervalo = interval_level,
    eee_imacec = eee_target$eee_imacec[1],
    eee_survey_period = eee_target$survey_period[1],
    imacec_observado = observed,
    fecha_actualizacion = Sys.Date()
  )

  list(
    model_key = model_key,
    model_label = model_specs[[model_key]]$label,
    corte = model_specs[[model_key]]$corte,
    model = fitted$model,
    Data = data,
    train = fitted$train,
    history = fit_history,
    proyeccion = projection,
    newdata = newdata
  )
}

run_nowcast_safe <- function(model_key, data, eee) {
  tryCatch(
    run_nowcast(model_key, data = data, eee = eee),
    error = function(e) {
      warning("No se pudo estimar ", model_key, ": ", conditionMessage(e), call. = FALSE)
      NULL
    }
  )
}

run_winner_models <- function(data = build_imacec_dataset(), eee = get_eee_expectations()) {
  results <- list(
    m4 = run_nowcast_safe("m4", data, eee),
    m8p = run_nowcast_safe("m8p", data, eee)
  )
  results <- purrr::compact(results)
  if (!length(results)) stop("No se pudo estimar M4 ni M8P.")
  results
}

fit_for_oos <- function(data, model_key, period) {
  required <- model_required_variables(model_key)
  target <- data |>
    dplyr::filter(Periodo == period) |>
    dplyr::slice_head(n = 1)
  if (!nrow(target) || !stats::complete.cases(target[, c("imacec", required), drop = FALSE])) return(NULL)
  tryCatch({
    fitted <- fit_winner(data, model_key, period)
    pred <- as.numeric(stats::predict(fitted$model, newdata = target))
    if (!is.finite(pred) || abs(pred) > 50) return(NULL)
    tibble::tibble(
      Periodo = period,
      variable = "IMACEC total",
      modelo = model_specs[[model_key]]$label,
      model_key = model_key,
      observado = target$imacec[1],
      predicho = pred
    )
  }, error = function(e) NULL)
}

compute_pseudo_oos <- function(data, start = oos_start_date) {
  periods <- data |>
    dplyr::filter(Periodo >= start, !is.na(imacec)) |>
    dplyr::pull(Periodo)
  predictions <- purrr::map_dfr(names(model_specs), function(key) {
    purrr::map_dfr(periods, ~ fit_for_oos(data, key, .x))
  })
  metrics <- predictions |>
    dplyr::group_by(variable, modelo, model_key) |>
    dplyr::summarise(
      N = dplyr::n(),
      RMSE = sqrt(mean((observado - predicho)^2)),
      MAE = mean(abs(observado - predicho)),
      periodo_inicio = min(Periodo),
      periodo_fin = max(Periodo),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      Periodo = paste0(format(periodo_inicio, "%Y-%m"), " a ", format(periodo_fin, "%Y-%m")),
      nota = "Pseudo-OOS recursivo con información final; no reconstruye revisiones históricas."
    ) |>
    dplyr::select(variable, modelo, model_key, N, RMSE, MAE, Periodo, nota)
  list(predictions = predictions, metrics = metrics)
}
