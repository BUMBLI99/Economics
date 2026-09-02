# ============================================================
# imacec_models.R
# Ciclo mensual y especificaciones fijas M4/M8P
# ============================================================

target_specs <- list(
  total = list(response = "imacec_total", label = "IMACEC total", eee = "eee_imacec"),
  no_minero = list(response = "imacec_no_minero", label = "IMACEC no minero", eee = "eee_imacec_nm")
)

model_specs <- list(
  m4 = list(
    corte = "experimental", label = "M4 · Dinámico",
    rhs = c("venta_minorista", "monto_credito", "cantidad_credito", "{lag1}",
            "dias_habiles", "efecto_bisiesto_yoy", "mes_factor", "dummy_covid")
  ),
  m8p = list(
    corte = "ine", label = "M8P · INE + IVS real parsimonioso",
    rhs = c("cantidad_credito", "{lag1}", "avisos_laborales_lag1", "mineria",
            "manufactura", "comercio", "electricidad", "factor_ivs_real",
            "dias_habiles", "efecto_bisiesto_yoy", "monto_credito_real", "dummy_covid")
  )
)

model_formula <- function(model_key, target_key) {
  response <- target_specs[[target_key]]$response
  rhs <- gsub("{lag1}", paste0(response, "_lag1"), model_specs[[model_key]]$rhs, fixed = TRUE)
  stats::reformulate(rhs, response = response)
}

model_required_variables <- function(model_key, target_key, include_target = FALSE) {
  vars <- all.vars(model_formula(model_key, target_key))
  if (!include_target) vars <- setdiff(vars, target_specs[[target_key]]$response)
  vars
}

latest_observed_period <- function(data) {
  hit <- data |>
    dplyr::filter(!is.na(imacec_total), !is.na(imacec_no_minero)) |>
    dplyr::summarise(value = max(Periodo)) |>
    dplyr::pull(value)
  if (!length(hit) || is.na(hit)) stop("No existe un IMACEC efectivo común para total y no minero.")
  as.Date(hit)
}

eee_for_period <- function(eee, period, target_key) {
  value_col <- target_specs[[target_key]]$eee
  hit <- eee |>
    dplyr::filter(Periodo == as.Date(period)) |>
    dplyr::arrange(dplyr::desc(survey_period)) |>
    dplyr::slice_head(n = 1)
  if (!nrow(hit)) {
    return(tibble::tibble(
      survey_period = as.Date(NA), Periodo = as.Date(period), eee_value = NA_real_
    ))
  }
  hit |>
    dplyr::transmute(survey_period, Periodo, eee_value = .data[[value_col]])
}

target_has_information <- function(data, model_key, target_key, period) {
  required <- c("Periodo", model_required_variables(model_key, target_key))
  row <- data |>
    dplyr::filter(Periodo == as.Date(period)) |>
    dplyr::slice_head(n = 1)
  nrow(row) == 1 && all(required %in% names(row)) &&
    stats::complete.cases(row[, required, drop = FALSE])
}

build_cycle_state <- function(data, eee) {
  last_actual <- latest_observed_period(data)
  future_eee <- eee |>
    dplyr::filter(Periodo > last_actual, !is.na(eee_imacec) | !is.na(eee_imacec_nm)) |>
    dplyr::arrange(Periodo)
  has_eee <- nrow(future_eee) > 0
  target <- if (has_eee) max(future_eee$Periodo) else last_actual

  has_m4 <- has_eee && all(vapply(
    names(target_specs), function(key) target_has_information(data, "m4", key, target), logical(1)
  ))
  has_m8p <- has_eee && all(vapply(
    names(target_specs), function(key) target_has_information(data, "m8p", key, target), logical(1)
  ))

  if (!has_eee) {
    stage <- "official_review"
    label <- "Dato efectivo publicado · esperando la EEE del siguiente período"
    default_model <- "summary"
  } else if (has_m8p) {
    stage <- "ine"
    label <- "Corte INE completo · M8P es la estimación principal"
    default_model <- "m8p"
  } else if (has_m4) {
    stage <- "experimental"
    label <- "Corte experimental completo · M4 es la estimación principal"
    default_model <- "m4"
  } else {
    stage <- "eee_proxy"
    label <- "EEE publicada · señal provisional AR(1) hasta el corte experimental"
    default_model <- "proxy"
  }

  tibble::tibble(
    fecha_actualizacion = Sys.Date(),
    fecha_hora_actualizacion = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"),
    ultima_observacion_imacec = last_actual,
    periodo_objetivo = as.Date(target),
    siguiente_periodo_imacec = last_actual %m+% lubridate::months(1),
    ciclo_estado = stage,
    ciclo_estado_label = label,
    modelo_principal = default_model,
    tiene_eee = has_eee,
    tiene_experimentales = has_m4,
    tiene_ine = has_m8p
  )
}

fit_winner <- function(data, model_key, target_key, target_period) {
  formula <- model_formula(model_key, target_key)
  required <- c(target_specs[[target_key]]$response, model_required_variables(model_key, target_key))
  train <- data |>
    dplyr::filter(Periodo < as.Date(target_period)) |>
    tidyr::drop_na(dplyr::all_of(required))
  if (nrow(train) < min_training_obs) {
    stop(model_specs[[model_key]]$label, " / ", target_specs[[target_key]]$label,
         " tiene ", nrow(train), " observaciones; se requieren ", min_training_obs, ".")
  }
  fit <- stats::lm(formula, data = train)
  if (stats::df.residual(fit) < min_residual_df) {
    stop(model_specs[[model_key]]$label, " tiene solo ", stats::df.residual(fit),
         " grados de libertad residuales.")
  }
  list(model = fit, train = train, formula = formula)
}

predict_interval <- function(model, newdata, level = interval_level) {
  pred <- as.data.frame(stats::predict(model, newdata = newdata, interval = "prediction", level = level))
  tibble::tibble(fit = pred$fit, lwr = pred$lwr, upr = pred$upr)
}

run_nowcast <- function(model_key, target_key, target_period, data, eee) {
  if (!target_has_information(data, model_key, target_key, target_period)) {
    stop("El corte ", model_key, " no está completo para ", format(as.Date(target_period), "%Y-%m"), ".")
  }
  fitted <- fit_winner(data, model_key, target_key, target_period)
  response <- target_specs[[target_key]]$response
  newdata <- data |>
    dplyr::filter(Periodo == as.Date(target_period)) |>
    dplyr::slice_head(n = 1)
  prediction <- predict_interval(fitted$model, newdata)
  eee_target <- eee_for_period(eee, target_period, target_key)
  observed <- newdata[[response]][1]

  history <- fitted$train |>
    dplyr::transmute(
      Periodo, target_key = target_key, variable = target_specs[[target_key]]$label,
      observed = .data[[response]], fitted = as.numeric(stats::predict(fitted$model)),
      model_key = model_key, modelo = model_specs[[model_key]]$label,
      corte = model_specs[[model_key]]$corte, tipo = "Ajuste"
    )

  projection <- tibble::tibble(
    Periodo = as.Date(target_period), target_key = target_key,
    variable = target_specs[[target_key]]$label, corte = model_specs[[model_key]]$corte,
    model_key = model_key, modelo = model_specs[[model_key]]$label,
    estado = if (is.na(observed)) "Nowcast activo" else "Reestimación de referencia; el dato efectivo ya existe",
    forecast = as.numeric(prediction$fit), lwr = as.numeric(prediction$lwr),
    upr = as.numeric(prediction$upr), nivel_intervalo = interval_level,
    eee_value = as.numeric(eee_target$eee_value[1]),
    eee_survey_period = as.Date(eee_target$survey_period[1]),
    observed = as.numeric(observed), fecha_actualizacion = Sys.Date(),
    run_timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")
  )

  list(
    model_key = model_key, target_key = target_key,
    model_label = model_specs[[model_key]]$label,
    target_label = target_specs[[target_key]]$label, model = fitted$model,
    Data = data, train = fitted$train, history = history,
    proyeccion = projection, newdata = newdata
  )
}

run_proxy <- function(target_key, target_period, data, eee) {
  response <- target_specs[[target_key]]$response
  train <- data |>
    dplyr::filter(Periodo < as.Date(target_period), !is.na(.data[[response]])) |>
    dplyr::arrange(Periodo) |>
    dplyr::transmute(Periodo, value = .data[[response]], lag_value = dplyr::lag(.data[[response]])) |>
    tidyr::drop_na()
  if (nrow(train) < 24) stop("Muestra insuficiente para el AR(1) provisional.")
  fit <- stats::lm(value ~ lag_value, data = train)
  last_value <- data |>
    dplyr::filter(Periodo < as.Date(target_period), !is.na(.data[[response]])) |>
    dplyr::arrange(Periodo) |>
    dplyr::slice_tail(n = 1) |>
    dplyr::pull(.data[[response]])
  prediction <- predict_interval(fit, data.frame(lag_value = as.numeric(last_value)))
  eee_target <- eee_for_period(eee, target_period, target_key)

  history <- train |>
    dplyr::transmute(
      Periodo, target_key = target_key, variable = target_specs[[target_key]]$label,
      observed = value, fitted = as.numeric(stats::predict(fit)),
      model_key = "proxy", modelo = "AR(1) provisional", corte = "eee", tipo = "Ajuste"
    )
  projection <- tibble::tibble(
    Periodo = as.Date(target_period), target_key = target_key,
    variable = target_specs[[target_key]]$label, corte = "eee", model_key = "proxy",
    modelo = "AR(1) provisional", estado = "Señal temprana; no sustituye M4 ni M8P",
    forecast = as.numeric(prediction$fit), lwr = as.numeric(prediction$lwr),
    upr = as.numeric(prediction$upr), nivel_intervalo = interval_level,
    eee_value = as.numeric(eee_target$eee_value[1]),
    eee_survey_period = as.Date(eee_target$survey_period[1]), observed = NA_real_,
    fecha_actualizacion = Sys.Date(), run_timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")
  )
  list(
    model_key = "proxy", target_key = target_key, model_label = "AR(1) provisional",
    target_label = target_specs[[target_key]]$label, model = fit, Data = data,
    train = train, history = history, proyeccion = projection, newdata = NULL
  )
}

run_model_safe <- function(model_key, target_key, target_period, data, eee) {
  tryCatch(
    if (model_key == "proxy") run_proxy(target_key, target_period, data, eee)
    else run_nowcast(model_key, target_key, target_period, data, eee),
    error = function(e) {
      warning("No se pudo estimar ", model_key, " / ", target_key, ": ", conditionMessage(e), call. = FALSE)
      NULL
    }
  )
}

run_cycle_models <- function(data, eee, cycle) {
  keys <- switch(
    cycle$ciclo_estado[1], eee_proxy = "proxy", experimental = "m4",
    ine = c("m4", "m8p"), official_review = c("m4", "m8p"), character()
  )
  results <- list()
  for (model_key in keys) {
    for (target_key in names(target_specs)) {
      name <- paste(model_key, target_key, sep = "_")
      results[[name]] <- run_model_safe(
        model_key, target_key, cycle$periodo_objetivo[1], data, eee
      )
    }
  }
  purrr::compact(results)
}

fit_for_oos <- function(data, model_key, target_key, period) {
  response <- target_specs[[target_key]]$response
  if (!target_has_information(data, model_key, target_key, period)) return(NULL)
  target <- data |>
    dplyr::filter(Periodo == as.Date(period), !is.na(.data[[response]])) |>
    dplyr::slice_head(n = 1)
  if (!nrow(target)) return(NULL)
  tryCatch({
    fitted <- fit_winner(data, model_key, target_key, period)
    pred <- as.numeric(stats::predict(fitted$model, newdata = target))
    if (!is.finite(pred) || abs(pred) > 50) return(NULL)
    tibble::tibble(
      Periodo = as.Date(period), variable = target_specs[[target_key]]$label,
      modelo = model_specs[[model_key]]$label, model_key = model_key,
      observado = target[[response]][1], predicho = pred
    )
  }, error = function(e) NULL)
}

compute_pseudo_oos <- function(data, start = oos_start_date) {
  periods <- data |>
    dplyr::filter(Periodo >= start, !is.na(imacec_total), !is.na(imacec_no_minero)) |>
    dplyr::pull(Periodo)
  predictions <- purrr::map_dfr(names(model_specs), function(model_key) {
    purrr::map_dfr(names(target_specs), function(target_key) {
      purrr::map_dfr(periods, ~ fit_for_oos(data, model_key, target_key, .x))
    })
  })
  metrics <- predictions |>
    dplyr::group_by(variable, modelo, model_key) |>
    dplyr::summarise(
      N = dplyr::n(), RMSE = sqrt(mean((observado - predicho)^2)),
      MAE = mean(abs(observado - predicho)), periodo_inicio = min(Periodo),
      periodo_fin = max(Periodo), .groups = "drop"
    ) |>
    dplyr::mutate(
      Periodo = paste0(format(periodo_inicio, "%Y-%m"), " a ", format(periodo_fin, "%Y-%m")),
      nota = "Pseudo-OOS recursivo con información final; no reconstruye revisiones históricas."
    ) |>
    dplyr::select(variable, modelo, model_key, N, RMSE, MAE, Periodo, nota)
  list(predictions = predictions, metrics = metrics)
}
