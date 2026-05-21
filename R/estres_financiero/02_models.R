# ============================================================
# 02_models.R
# Modelos de normalización por fundamentos y construcción del índice.
# ============================================================

estres_check_min_obs <- function(model_data, model_name, min_obs = 250) {
  if (nrow(model_data) < min_obs) {
    stop(
      "Muy pocas observaciones para estimar ", model_name, ": ", nrow(model_data),
      ". Revisa datos faltantes, APIs o fecha de inicio.",
      call. = FALSE
    )
  }
  invisible(model_data)
}

estres_available_predictors <- function(data, candidates, min_non_na = 250) {
  keep <- vapply(candidates, function(var) {
    if (!var %in% names(data)) return(FALSE)
    x <- data[[var]]
    sum(!is.na(x)) >= min_non_na && isTRUE(stats::sd(x, na.rm = TRUE) > 0)
  }, logical(1))

  candidates[keep]
}

estres_fit_lm_dynamic <- function(data, dependent, predictors, model_name, min_obs = 250) {
  predictors <- estres_available_predictors(data, predictors, min_non_na = min_obs)

  if (length(predictors) == 0) {
    stop("No hay predictores disponibles para ", model_name, call. = FALSE)
  }

  model_data <- data |>
    dplyr::select(dplyr::all_of(c("date", dependent, predictors))) |>
    tidyr::drop_na()

  # Si la muestra queda demasiado chica por un predictor opcional, se remueven
  # predictores desde el final hasta recuperar una muestra suficiente.
  while (nrow(model_data) < min_obs && length(predictors) > 1) {
    predictors <- predictors[-length(predictors)]
    model_data <- data |>
      dplyr::select(dplyr::all_of(c("date", dependent, predictors))) |>
      tidyr::drop_na()
  }

  estres_check_min_obs(model_data, model_name, min_obs = min_obs)

  formula <- stats::as.formula(paste(dependent, "~", paste(predictors, collapse = " + ")))
  model <- stats::lm(formula, data = model_data)

  list(model = model, model_data = model_data, predictors = predictors)
}

estres_estimate_fx_model <- function(market_data) {
  # Especificación central, fiel a la lógica original de ExchangeReg:
  # log(USDCLP) ~ tendencia + CPI relativo + cobre + WTI + VIX + dólar global + CNY + bolsas.
  # Si CPI relativo no existe porque se usa base local antigua, se omite automáticamente.
  candidates <- c(
    "trend", "l_cpi_rel_chl_us", "l_pcu", "l_wti", "l_vix",
    "l_dtw", "l_cny", "l_eq_nsq", "l_eq_cny"
  )

  fit <- estres_fit_lm_dynamic(
    data = market_data,
    dependent = "l_clp",
    predictors = candidates,
    model_name = "modelo de tipo de cambio"
  )

  fitted_data <- fit$model_data |>
    dplyr::mutate(
      fitted_l_clp = stats::fitted(fit$model),
      fitted_clp = exp(.data$fitted_l_clp),
      res_fx = stats::resid(fit$model),
      z_fx = estres_zscore(.data$res_fx)
    ) |>
    dplyr::select(date, fitted_clp, res_fx, z_fx) |>
    dplyr::left_join(
      market_data |> dplyr::select(date, clp),
      by = "date"
    ) |>
    dplyr::select(date, clp, fitted_clp, res_fx, z_fx)

  list(model = fit$model, fitted = fitted_data, predictors = fit$predictors)
}

estres_estimate_y10_model <- function(market_data) {
  candidates <- c("trend", "y10_tsy", "l_vix", "l_dtw", "l_cny", "l_eq_nsq")

  fit <- estres_fit_lm_dynamic(
    data = market_data,
    dependent = "y10_clp",
    predictors = candidates,
    model_name = "modelo de tasa soberana 10Y"
  )

  fitted_data <- fit$model_data |>
    dplyr::mutate(
      fitted_y10_clp = stats::fitted(fit$model),
      res_y10 = stats::resid(fit$model),
      z_y10 = estres_zscore(.data$res_y10)
    ) |>
    dplyr::select(date, y10_clp, fitted_y10_clp, res_y10, z_y10)

  list(model = fit$model, fitted = fitted_data, predictors = fit$predictors)
}

estres_classify_regime <- function(x) {
  dplyr::case_when(
    is.na(x) ~ NA_character_,
    x >= 1.5 ~ "Estrés alto",
    x >= 0.75 ~ "Estrés moderado",
    x <= -0.75 ~ "Condiciones benignas",
    TRUE ~ "Condiciones neutrales"
  )
}

estres_construct_index <- function(fx_fit, y10_fit) {
  fx_fit$fitted |>
    dplyr::inner_join(y10_fit$fitted, by = "date") |>
    dplyr::arrange(.data$date) |>
    dplyr::mutate(
      stress_market = (.data$z_fx + .data$z_y10) / 2,
      stress_market_30d = estres_roll_mean(.data$stress_market, width = 30, min_obs = 20),
      stress_fx_30d = estres_roll_mean(.data$z_fx, width = 30, min_obs = 20),
      stress_y10_30d = estres_roll_mean(.data$z_y10, width = 30, min_obs = 20),
      regime = estres_classify_regime(.data$stress_market_30d)
    )
}



estres_expanding_oos_component <- function(market_data,
                                           dependent,
                                           predictors,
                                           model_name,
                                           min_obs = 500,
                                           step = 5) {
  # Residuo pseudo out-of-sample con ventana expansiva.
  # La predicción de cada fecha se obtiene estimando el modelo solo con
  # información anterior a esa fecha. Se evalúa cada `step` observaciones
  # para mantener el pipeline liviano en datos diarios.

  predictors <- estres_available_predictors(market_data, predictors, min_non_na = min_obs)

  if (length(predictors) == 0) {
    return(tibble::tibble())
  }

  model_data <- market_data |>
    dplyr::select(dplyr::all_of(c("date", dependent, predictors))) |>
    tidyr::drop_na() |>
    dplyr::arrange(.data$date)

  if (nrow(model_data) < min_obs + 20) {
    return(tibble::tibble())
  }

  formula <- stats::as.formula(paste(dependent, "~", paste(predictors, collapse = " + ")))
  eval_idx <- seq(from = min_obs + 1L, to = nrow(model_data), by = step)
  preds <- vector("list", length(eval_idx))

  for (j in seq_along(eval_idx)) {
    i <- eval_idx[[j]]
    train <- model_data[seq_len(i - 1L), , drop = FALSE]
    test  <- model_data[i, , drop = FALSE]

    fit <- tryCatch(stats::lm(formula, data = train), error = function(e) NULL)
    if (is.null(fit)) next

    pred <- tryCatch(as.numeric(stats::predict(fit, newdata = test)), error = function(e) NA_real_)
    actual <- as.numeric(test[[dependent]][[1]])
    res <- actual - pred
    res_sd <- stats::sd(stats::resid(fit), na.rm = TRUE)
    z <- if (is.finite(res_sd) && res_sd > 0) res / res_sd else NA_real_

    preds[[j]] <- tibble::tibble(
      date = test$date[[1]],
      model = model_name,
      dependent_variable = dependent,
      actual = actual,
      fitted_oos = pred,
      residual_oos = res,
      z_oos = z,
      n_train = stats::nobs(fit),
      predictors_used = paste(predictors, collapse = ", ")
    )
  }

  dplyr::bind_rows(preds)
}

estres_construct_oos_index <- function(market_data, min_obs = 500, step = 5) {
  fx_candidates <- c(
    "trend", "l_cpi_rel_chl_us", "l_pcu", "l_wti", "l_vix",
    "l_dtw", "l_cny", "l_eq_nsq", "l_eq_cny"
  )

  y10_candidates <- c("trend", "y10_tsy", "l_vix", "l_dtw", "l_cny", "l_eq_nsq")

  fx_oos <- estres_expanding_oos_component(
    market_data = market_data,
    dependent = "l_clp",
    predictors = fx_candidates,
    model_name = "Tipo de cambio USD/CLP",
    min_obs = min_obs,
    step = step
  )

  y10_oos <- estres_expanding_oos_component(
    market_data = market_data,
    dependent = "y10_clp",
    predictors = y10_candidates,
    model_name = "Tasa soberana 10Y CLP",
    min_obs = min_obs,
    step = step
  )

  if (nrow(fx_oos) == 0 || nrow(y10_oos) == 0) {
    return(tibble::tibble())
  }

  fx_out <- fx_oos |>
    dplyr::transmute(
      date,
      fitted_clp_oos = exp(.data$fitted_oos),
      res_fx_oos = .data$residual_oos,
      z_fx_oos = .data$z_oos,
      n_train_fx = .data$n_train
    ) |>
    dplyr::left_join(market_data |> dplyr::select(date, clp), by = "date")

  y10_out <- y10_oos |>
    dplyr::transmute(
      date,
      y10_clp_oos = .data$actual,
      fitted_y10_clp_oos = .data$fitted_oos,
      res_y10_oos = .data$residual_oos,
      z_y10_oos = .data$z_oos,
      n_train_y10 = .data$n_train
    )

  fx_out |>
    dplyr::inner_join(y10_out, by = "date") |>
    dplyr::arrange(.data$date) |>
    dplyr::mutate(
      stress_market_oos = (.data$z_fx_oos + .data$z_y10_oos) / 2,
      stress_market_oos_30d = estres_roll_mean(.data$stress_market_oos, width = 6, min_obs = 4),
      regime_oos = estres_classify_regime(.data$stress_market_oos_30d)
    )
}

estres_model_coefficients <- function(fx_fit, y10_fit) {
  dplyr::bind_rows(
    broom::tidy(fx_fit$model, conf.int = TRUE) |>
      dplyr::mutate(
        model = "Tipo de cambio USD/CLP",
        dependent_variable = "log(USDCLP)",
        predictors_used = paste(fx_fit$predictors, collapse = ", "),
        .before = 1
      ),
    broom::tidy(y10_fit$model, conf.int = TRUE) |>
      dplyr::mutate(
        model = "Tasa soberana 10Y CLP",
        dependent_variable = "10YCLP",
        predictors_used = paste(y10_fit$predictors, collapse = ", "),
        .before = 1
      )
  )
}

estres_model_diagnostics <- function(fx_fit, y10_fit) {
  fx_glance <- broom::glance(fx_fit$model)
  y10_glance <- broom::glance(y10_fit$model)

  tibble::tibble(
    model = c("Tipo de cambio USD/CLP", "Tasa soberana 10Y CLP"),
    dependent_variable = c("log(USDCLP)", "10YCLP"),
    predictors_used = c(paste(fx_fit$predictors, collapse = ", "), paste(y10_fit$predictors, collapse = ", ")),
    n_obs = c(stats::nobs(fx_fit$model), stats::nobs(y10_fit$model)),
    r_squared = c(fx_glance$r.squared, y10_glance$r.squared),
    adj_r_squared = c(fx_glance$adj.r.squared, y10_glance$adj.r.squared),
    sample_start = c(min(fx_fit$fitted$date, na.rm = TRUE), min(y10_fit$fitted$date, na.rm = TRUE)),
    sample_end = c(max(fx_fit$fitted$date, na.rm = TRUE), max(y10_fit$fitted$date, na.rm = TRUE)),
    residual_sd = c(stats::sd(fx_fit$fitted$res_fx, na.rm = TRUE), stats::sd(y10_fit$fitted$res_y10, na.rm = TRUE))
  )
}

estres_detect_episodes <- function(index_data, n = 15, min_distance_days = 30) {
  candidates <- index_data |>
    dplyr::filter(!is.na(.data$stress_market_30d)) |>
    dplyr::arrange(dplyr::desc(.data$stress_market_30d))

  selected <- vector("list", 0)

  for (i in seq_len(nrow(candidates))) {
    candidate <- candidates[i, ]
    candidate_date <- candidate$date[[1]]

    far_enough <- if (length(selected) == 0) {
      TRUE
    } else {
      selected_dates <- as.Date(vapply(selected, function(x) as.character(x$date[[1]]), character(1)))
      all(abs(as.numeric(candidate_date - selected_dates)) >= min_distance_days)
    }

    if (far_enough) selected[[length(selected) + 1]] <- candidate
    if (length(selected) >= n) break
  }

  dplyr::bind_rows(selected) |>
    dplyr::select(date, stress_market_30d, stress_market, z_fx, z_y10, regime) |>
    dplyr::arrange(.data$date)
}

estres_write_outputs <- function(index_data, fx_fit, y10_fit, root = estres_project_root(), oos_index = NULL) {
  estres_make_dirs(root)

  processed_dir <- file.path(root, "data/processed/estres_financiero")
  table_dir <- file.path(root, "outputs/tables/estres_financiero")

  readr::write_csv(index_data, file.path(processed_dir, "stress_index_chile.csv"))
  readr::write_csv(index_data, file.path(root, "data/processed/estres_financiero_chile.csv"))
  readr::write_csv(estres_model_coefficients(fx_fit, y10_fit), file.path(processed_dir, "model_coefficients.csv"))
  readr::write_csv(estres_model_diagnostics(fx_fit, y10_fit), file.path(processed_dir, "model_diagnostics.csv"))

  latest <- index_data |>
    dplyr::filter(
      !is.na(.data$stress_market),
      !is.na(.data$stress_market_30d),
      !is.na(.data$z_fx),
      !is.na(.data$z_y10)
    ) |>
    dplyr::slice_tail(n = 1)

  readr::write_csv(latest, file.path(processed_dir, "latest_snapshot.csv"))
  readr::write_csv(estres_detect_episodes(index_data), file.path(table_dir, "episodios_estres.csv"))

  if (!is.null(oos_index) && nrow(oos_index) > 0) {
    readr::write_csv(oos_index, file.path(processed_dir, "stress_index_chile_oos.csv"))
  }

  invisible(index_data)
}
