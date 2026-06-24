# ============================================================
# imacec_models.R
# Modelos y nowcast IMACEC
# ============================================================

# -------------------------------------------------------------------
# Utilidades de período objetivo y supuestos
# -------------------------------------------------------------------

get_target_period <- function(Data) {
  Data |>
    dplyr::filter(!is.na(imacec)) |>
    dplyr::summarise(maxp = max(Periodo)) |>
    dplyr::pull(maxp) %m+% months(1)
}

make_default_assumptions <- function(Data, periodo_objetivo = get_target_period(Data), vars = NULL) {
  if (is.null(vars)) {
    vars <- c(
      "monto_credito", "cantidad_credito", "venta_minorista", "uf",
      "mineria", "manufactura", "comercio", "electricidad", "desempleo"
    )
  }

  vars <- intersect(vars, names(Data))

  out <- lapply(vars, function(v) {
    Data |>
      dplyr::filter(Periodo < periodo_objetivo) |>
      dplyr::arrange(Periodo) |>
      dplyr::pull(dplyr::all_of(v)) |>
      last_non_na()
  })
  names(out) <- vars
  out
}

model_label_from_key <- function(model_key) {
  dplyr::case_when(
    model_key == "base" ~ "Modelo con estadísticas experimentales",
    model_key == "ine"  ~ "Modelo con indicadores sectoriales INE",
    TRUE ~ model_key
  )
}

# -------------------------------------------------------------------
# Especificaciones
# -------------------------------------------------------------------

fit_models_base <- function(Data) {
  Data_reg <- Data |>
    tidyr::drop_na(
      imacec, imacec_nm,
      monto_credito, cantidad_credito, venta_minorista, uf,
      dias_habiles, mes, feb, bisiesto, dias_mes,
      d_2022_04, d_2020_04, d_2020_05,
      imacec_lag1, imacec_lag2, imacec_lag4, imacec_lag12,
      imacec_nm_lag1, imacec_nm_lag2, imacec_nm_lag4, imacec_nm_lag12
    )

  modelo_imacec <- stats::lm(
    imacec ~ imacec_lag1 + imacec_lag2 + imacec_lag4 + imacec_lag12 +
      venta_minorista + monto_credito + dias_habiles + feb + bisiesto +
      dias_mes + mes + uf + d_2022_04 + d_2020_04 + d_2020_05,
    data = Data_reg
  )

  modelo_imacec_nm <- stats::lm(
    imacec_nm ~ imacec_nm_lag1 + imacec_nm_lag2 + imacec_nm_lag4 + imacec_nm_lag12 +
      venta_minorista + monto_credito + dias_habiles + feb + bisiesto +
      dias_mes + mes + uf + d_2022_04 + d_2020_04 + d_2020_05,
    data = Data_reg
  )

  list(
    Data_reg = Data_reg,
    modelo_imacec = modelo_imacec,
    modelo_imacec_nm = modelo_imacec_nm,
    model_key = "base",
    model_label = model_label_from_key("base")
  )
}

fit_models_ine <- function(Data_ine) {
  Data_reg_ine <- Data_ine |>
    tidyr::drop_na(
      imacec, imacec_nm,
      monto_credito, venta_minorista, uf,
      dias_habiles, mes, feb, bisiesto, dias_mes,
      d_2022_04, d_2020_04, d_2020_05, d_2024_06,
      imacec_lag1, imacec_nm_lag1, t,
      mineria, manufactura, comercio, electricidad, desempleo_lag1
    )

  modelo_imacec_ine <- stats::lm(
    imacec ~ t + imacec_lag1 +
      venta_minorista + monto_credito + uf +
      mineria + manufactura + comercio + electricidad +
      dias_habiles + feb + bisiesto + dias_mes + mes +
      d_2022_04 + d_2020_04 + d_2020_05 + d_2024_06,
    data = Data_reg_ine
  )

  modelo_imacec_nm_ine <- stats::lm(
    imacec_nm ~ t + imacec_nm_lag1 +
      venta_minorista + monto_credito + uf +
      mineria + manufactura + comercio + electricidad + desempleo_lag1 +
      dias_habiles + feb + bisiesto + dias_mes + mes +
      d_2022_04 + d_2020_04 + d_2020_05 + d_2024_06,
    data = Data_reg_ine
  )

  list(
    Data_reg = Data_reg_ine,
    modelo_imacec = modelo_imacec_ine,
    modelo_imacec_nm = modelo_imacec_nm_ine,
    model_key = "ine",
    model_label = model_label_from_key("ine")
  )
}

# -------------------------------------------------------------------
# Construcción de newdata
# -------------------------------------------------------------------

build_newdata_from_model <- function(modelo, periodo_objetivo, Data, cal_df, assumptions = list()) {
  terms_needed <- attr(stats::terms(modelo), "term.labels")
  row_list <- list()

  for (term in terms_needed) {
    if (term == "mes") {
      row_list[[term]] <- factor(lubridate::month(periodo_objetivo), levels = 1:12)

    } else if (term == "feb") {
      row_list[[term]] <- as.integer(lubridate::month(periodo_objetivo) == 2)

    } else if (term == "bisiesto") {
      row_list[[term]] <- as.integer(lubridate::leap_year(periodo_objetivo))

    } else if (term == "dias_mes") {
      row_list[[term]] <- as.numeric(lubridate::days_in_month(periodo_objetivo))

    } else if (term %in% c("d_2022_04", "d_2020_04", "d_2020_05", "d_2024_06", "d_postCov")) {
      row_list[[term]] <- switch(
        term,
        d_2022_04 = as.integer(periodo_objetivo == as.Date("2022-04-01")),
        d_2020_04 = as.integer(periodo_objetivo == as.Date("2020-04-01")),
        d_2020_05 = as.integer(periodo_objetivo == as.Date("2020-05-01")),
        d_2024_06 = as.integer(periodo_objetivo == as.Date("2024-06-01")),
        d_postCov = as.integer(periodo_objetivo >= as.Date("2022-01-01"))
      )

    } else if (term == "t") {
      row_list[[term]] <- max(Data$t, na.rm = TRUE) + 1

    } else if (term == "dias_habiles") {
      dh <- cal_df |>
        dplyr::filter(Periodo == periodo_objetivo) |>
        dplyr::pull(dias_habiles)
      if (length(dh) == 0 || is.na(dh[1])) stop("Faltan días hábiles para el mes objetivo.")
      row_list[[term]] <- as.numeric(dh[1])

    } else if (grepl("_lag[0-9]+$", term)) {
      base_var <- sub("_lag[0-9]+$", "", term)
      lag_n <- as.integer(sub("^.*_lag([0-9]+)$", "\\1", term))
      ref_period <- periodo_objetivo %m-% months(lag_n)

      val <- Data |>
        dplyr::filter(Periodo == ref_period) |>
        dplyr::pull(dplyr::all_of(base_var))

      if (length(val) == 0 || is.na(val[1])) {
        stop("No se pudo construir ", term, " usando ", base_var, " en ", format(ref_period, "%Y-%m"))
      }
      row_list[[term]] <- as.numeric(val[1])

    } else {
      val <- Data |>
        dplyr::filter(Periodo == periodo_objetivo) |>
        dplyr::pull(dplyr::all_of(term))

      if (length(val) > 0 && !is.na(val[1])) {
        row_list[[term]] <- as.numeric(val[1])
      } else if (!is.null(assumptions[[term]]) && !is.na(assumptions[[term]])) {
        row_list[[term]] <- as.numeric(assumptions[[term]])
      } else {
        fallback <- Data |>
          dplyr::filter(Periodo < periodo_objetivo) |>
          dplyr::arrange(Periodo) |>
          dplyr::pull(dplyr::all_of(term)) |>
          last_non_na()
        if (is.na(fallback)) stop("Falta valor para ", term, " en el mes objetivo.")
        row_list[[term]] <- fallback
      }
    }
  }

  newdata <- as.data.frame(row_list, check.names = FALSE)
  newdata <- newdata[, terms_needed, drop = FALSE]
  rownames(newdata) <- NULL
  newdata
}

# Para evaluación pseudo out-of-sample: se estima con información hasta t-1,
# pero se permite usar predictores contemporáneos finales del período evaluado.
# No es evaluación con vintages en tiempo real.
build_newdata_oos_from_model <- function(modelo, periodo_objetivo, Data_train, Data_available, cal_df, assumptions = list()) {
  terms_needed <- attr(stats::terms(modelo), "term.labels")
  row_list <- list()

  for (term in terms_needed) {
    if (term == "mes") {
      row_list[[term]] <- factor(lubridate::month(periodo_objetivo), levels = 1:12)

    } else if (term == "feb") {
      row_list[[term]] <- as.integer(lubridate::month(periodo_objetivo) == 2)

    } else if (term == "bisiesto") {
      row_list[[term]] <- as.integer(lubridate::leap_year(periodo_objetivo))

    } else if (term == "dias_mes") {
      row_list[[term]] <- as.numeric(lubridate::days_in_month(periodo_objetivo))

    } else if (term %in% c("d_2022_04", "d_2020_04", "d_2020_05", "d_2024_06", "d_postCov")) {
      row_list[[term]] <- switch(
        term,
        d_2022_04 = as.integer(periodo_objetivo == as.Date("2022-04-01")),
        d_2020_04 = as.integer(periodo_objetivo == as.Date("2020-04-01")),
        d_2020_05 = as.integer(periodo_objetivo == as.Date("2020-05-01")),
        d_2024_06 = as.integer(periodo_objetivo == as.Date("2024-06-01")),
        d_postCov = as.integer(periodo_objetivo >= as.Date("2022-01-01"))
      )

    } else if (term == "t") {
      row_list[[term]] <- max(Data_train$t, na.rm = TRUE) + 1

    } else if (term == "dias_habiles") {
      dh <- cal_df |>
        dplyr::filter(Periodo == periodo_objetivo) |>
        dplyr::pull(dias_habiles)
      if (length(dh) == 0 || is.na(dh[1])) stop("Faltan días hábiles para ", format(periodo_objetivo, "%Y-%m"))
      row_list[[term]] <- as.numeric(dh[1])

    } else if (grepl("_lag[0-9]+$", term)) {
      base_var <- sub("_lag[0-9]+$", "", term)
      lag_n <- as.integer(sub("^.*_lag([0-9]+)$", "\\1", term))
      ref_period <- periodo_objetivo %m-% months(lag_n)

      val <- Data_available |>
        dplyr::filter(Periodo == ref_period) |>
        dplyr::pull(dplyr::all_of(base_var))

      if (length(val) == 0 || is.na(val[1])) stop("No se pudo construir ", term, " para ", format(periodo_objetivo, "%Y-%m"))
      row_list[[term]] <- as.numeric(val[1])

    } else {
      val <- Data_available |>
        dplyr::filter(Periodo == periodo_objetivo) |>
        dplyr::pull(dplyr::all_of(term))

      if (length(val) > 0 && !is.na(val[1])) {
        row_list[[term]] <- as.numeric(val[1])
      } else if (!is.null(assumptions[[term]]) && !is.na(assumptions[[term]])) {
        row_list[[term]] <- as.numeric(assumptions[[term]])
      } else {
        fallback <- Data_train |>
          dplyr::arrange(Periodo) |>
          dplyr::pull(dplyr::all_of(term)) |>
          last_non_na()
        if (is.na(fallback)) stop("Falta valor para ", term, " en evaluación pseudo-OOS.")
        row_list[[term]] <- fallback
      }
    }
  }

  newdata <- as.data.frame(row_list, check.names = FALSE)
  newdata <- newdata[, terms_needed, drop = FALSE]
  rownames(newdata) <- NULL
  newdata
}

predict_confint <- function(modelo, newdata, level = 0.95) {
  pred <- stats::predict(modelo, newdata = newdata, se.fit = TRUE)
  fit  <- as.numeric(pred$fit)
  se   <- as.numeric(pred$se.fit)
  df   <- stats::df.residual(modelo)
  crit <- stats::qt((1 + level) / 2, df = df)

  tibble::tibble(
    fit = fit,
    lwr = fit - crit * se,
    upr = fit + crit * se
  )
}

# -------------------------------------------------------------------
# Ejecución nowcast actual
# -------------------------------------------------------------------

run_nowcast <- function(model = c("ine", "base"), assumptions = NULL) {
  model <- match.arg(model)
  cal_df <- read_calendar()

  if (model == "base") {
    Data_full <- build_dataset()
    fits <- fit_models_base(Data_full)
  } else {
    Data_full <- build_dataset_ine()
    fits <- fit_models_ine(Data_full)
  }

  Data_fit <- fits$Data_reg |>
    dplyr::mutate(
      imacec_fit = as.numeric(stats::predict(fits$modelo_imacec)),
      imacec_nm_fit = as.numeric(stats::predict(fits$modelo_imacec_nm)),
      modelo = fits$model_label,
      model_key = fits$model_key
    )

  periodo_objetivo <- get_target_period(Data_full)
  if (is.null(assumptions)) assumptions <- make_default_assumptions(Data_full, periodo_objetivo)

  newdata_imacec <- build_newdata_from_model(
    fits$modelo_imacec, periodo_objetivo, Data_full, cal_df, assumptions
  )

  newdata_imacec_nm <- build_newdata_from_model(
    fits$modelo_imacec_nm, periodo_objetivo, Data_full, cal_df, assumptions
  )

  pred_total <- predict_confint(fits$modelo_imacec, newdata_imacec)
  pred_nm    <- predict_confint(fits$modelo_imacec_nm, newdata_imacec_nm)

  proyeccion <- tibble::tibble(
    Periodo = periodo_objetivo,
    imacec_predicho = pred_total$fit,
    imacec_lwr = pred_total$lwr,
    imacec_upr = pred_total$upr,
    imacec_nm_predicho = pred_nm$fit,
    imacec_nm_lwr = pred_nm$lwr,
    imacec_nm_upr = pred_nm$upr,
    modelo = fits$model_label,
    model_key = fits$model_key,
    fecha_actualizacion = Sys.Date()
  )

  list(
    Data = Data_fit,
    Data_full = Data_full,
    modelo_imacec = fits$modelo_imacec,
    modelo_imacec_nm = fits$modelo_imacec_nm,
    proyeccion = proyeccion,
    newdata_imacec = newdata_imacec,
    newdata_imacec_nm = newdata_imacec_nm,
    model_label = fits$model_label,
    model_key = fits$model_key
  )
}

run_nowcast_safe <- function(model) {
  tryCatch(
    run_nowcast(model = model),
    error = function(e) {
      warning("No se pudo estimar modelo '", model, "': ", conditionMessage(e), call. = FALSE)
      NULL
    }
  )
}

choose_active_nowcast <- function(results) {
  if (!is.null(results$ine)) return(results$ine)
  if (!is.null(results$base)) return(results$base)
  stop("No se pudo estimar ningún modelo IMACEC.")
}
