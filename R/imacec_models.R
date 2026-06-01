# ============================================================
# imacec_models.R
# Modelos, selección de vintage y nowcast IMACEC
# ============================================================

get_target_period <- function(Data) {
  Data |>
    dplyr::filter(!is.na(imacec)) |>
    dplyr::summarise(maxp = max(Periodo)) |>
    dplyr::pull(maxp) %m+% lubridate::months(1)
}

last_observed_period <- function(Data) {
  Data |>
    dplyr::filter(!is.na(imacec)) |>
    dplyr::summarise(maxp = max(Periodo)) |>
    dplyr::pull(maxp)
}

mean_last_non_na <- function(x, n = 3) {
  x <- x[!is.na(x)]
  if (length(x) == 0) return(NA_real_)
  mean(utils::tail(x, n), na.rm = TRUE)
}

current_value <- function(Data, periodo, var) {
  if (!var %in% names(Data)) return(NA_real_)
  val <- Data |>
    dplyr::filter(Periodo == periodo) |>
    dplyr::pull(dplyr::all_of(var))
  if (length(val) == 0 || is.na(val[1])) return(NA_real_)
  as.numeric(val[1])
}

has_current_value <- function(Data, periodo, var) {
  !is.na(current_value(Data, periodo, var))
}

has_all_current <- function(Data, periodo, vars) {
  all(vapply(vars, function(v) has_current_value(Data, periodo, v), logical(1)))
}

has_any_current <- function(Data, periodo, vars, min_available = 1L) {
  sum(vapply(vars, function(v) has_current_value(Data, periodo, v), logical(1))) >= min_available
}

make_default_assumptions <- function(Data, periodo_objetivo = get_target_period(Data), vars = NULL) {
  if (is.null(vars)) {
    vars <- c(
      "monto_credito", "cantidad_credito", "venta_minorista", "uf",
      "mineria", "manufactura", "comercio", "electricidad", "desempleo"
    )
  }

  vars <- intersect(vars, names(Data))

  values <- lapply(vars, function(v) {
    hist <- Data |>
      dplyr::filter(Periodo < periodo_objetivo) |>
      dplyr::arrange(Periodo) |>
      dplyr::pull(dplyr::all_of(v))

    if (v %in% c("desempleo")) {
      last_non_na(hist)
    } else {
      mean_last_non_na(hist, n = 3)
    }
  })
  names(values) <- vars

  assumptions_tbl <- tibble::tibble(
    variable = vars,
    valor_asumido = as.numeric(unlist(values)),
    criterio = dplyr::if_else(vars %in% c("desempleo"), "Último dato disponible", "Promedio últimos 3 datos disponibles"),
    periodo_objetivo = periodo_objetivo
  )

  structure(values, assumptions_tbl = assumptions_tbl)
}

get_assumptions_table <- function(assumptions) {
  attr(assumptions, "assumptions_tbl") %||% tibble::tibble(
    variable = names(assumptions),
    valor_asumido = as.numeric(unlist(assumptions)),
    criterio = "Supuesto externo",
    periodo_objetivo = as.Date(NA)
  )
}

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

fit_models_experimental <- function(Data) {
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
      venta_minorista + monto_credito + cantidad_credito + dias_habiles +
      feb + bisiesto + dias_mes + mes + uf + d_2022_04 + d_2020_04 + d_2020_05,
    data = Data_reg
  )

  modelo_imacec_nm <- stats::lm(
    imacec_nm ~ imacec_nm_lag1 + imacec_nm_lag2 + imacec_nm_lag4 + imacec_nm_lag12 +
      venta_minorista + monto_credito + cantidad_credito + dias_habiles +
      feb + bisiesto + dias_mes + mes + uf + d_2022_04 + d_2020_04 + d_2020_05,
    data = Data_reg
  )

  list(
    Data_reg = Data_reg,
    modelo_imacec = modelo_imacec,
    modelo_imacec_nm = modelo_imacec_nm,
    model_label = "Modelo con indicadores experimentales/BCCh disponibles",
    stage = "experimental"
  )
}

fit_models_eee <- function(Data) {
  Data_reg_total <- Data |>
    tidyr::drop_na(
      imacec, eee_imacec,
      imacec_lag1, imacec_lag2, imacec_lag4, imacec_lag12,
      monto_credito, venta_minorista, uf,
      dias_habiles, mes, feb, bisiesto, dias_mes,
      d_2022_04, d_2020_04, d_2020_05
    )

  Data_reg_nm <- Data |>
    tidyr::drop_na(
      imacec_nm,
      imacec_nm_lag1, imacec_nm_lag2, imacec_nm_lag4, imacec_nm_lag12,
      monto_credito, venta_minorista, uf,
      dias_habiles, mes, feb, bisiesto, dias_mes,
      d_2022_04, d_2020_04, d_2020_05
    )

  modelo_imacec <- stats::lm(
    imacec ~ eee_imacec + imacec_lag1 + imacec_lag2 + imacec_lag4 + imacec_lag12 +
      venta_minorista + monto_credito + uf + dias_habiles + feb + bisiesto +
      dias_mes + mes + d_2022_04 + d_2020_04 + d_2020_05,
    data = Data_reg_total
  )

  modelo_imacec_nm <- stats::lm(
    imacec_nm ~ imacec_nm_lag1 + imacec_nm_lag2 + imacec_nm_lag4 + imacec_nm_lag12 +
      venta_minorista + monto_credito + uf + dias_habiles + feb + bisiesto +
      dias_mes + mes + d_2022_04 + d_2020_04 + d_2020_05,
    data = Data_reg_nm
  )

  Data_reg <- dplyr::bind_rows(
    Data_reg_total |> dplyr::mutate(.sample_model = "total"),
    Data_reg_nm |> dplyr::mutate(.sample_model = "no_minero")
  ) |>
    dplyr::distinct(Periodo, .keep_all = TRUE)

  list(
    Data_reg = Data_reg,
    modelo_imacec = modelo_imacec,
    modelo_imacec_nm = modelo_imacec_nm,
    model_label = "Modelo temprano con EEE y supuestos de indicadores contemporáneos",
    stage = "eee"
  )
}

fit_models_ine <- function(Data_ine) {
  Data_reg_ine <- Data_ine |>
    tidyr::drop_na(
      imacec, imacec_nm,
      monto_credito, venta_minorista, uf,
      dias_habiles, mes, feb, bisiesto, dias_mes,
      d_2022_04, d_2020_04, d_2020_05, d_2024_06,
      imacec_lag1, imacec_lag2, imacec_lag4, imacec_lag12,
      imacec_nm_lag1, imacec_nm_lag2, imacec_nm_lag4, imacec_nm_lag12,
      t,
      mineria, manufactura, comercio, electricidad, desempleo_lag1
    )

  modelo_imacec_ine <- stats::lm(
    imacec ~ t + imacec_lag1 + imacec_lag2 + imacec_lag4 + imacec_lag12 +
      venta_minorista + monto_credito + uf +
      mineria + manufactura + comercio + electricidad +
      dias_habiles + feb + bisiesto + dias_mes + mes +
      d_2022_04 + d_2020_04 + d_2020_05 + d_2024_06,
    data = Data_reg_ine
  )

  modelo_imacec_nm_ine <- stats::lm(
    imacec_nm ~ t + imacec_nm_lag1 + imacec_nm_lag2 + imacec_nm_lag4 + imacec_nm_lag12 +
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
    model_label = "Modelo con indicadores sectoriales INE",
    stage = "ine"
  )
}

stage_label <- function(stage) {
  dplyr::case_when(
    stage == "ine" ~ "Vintage INE: indicadores sectoriales completos",
    stage == "experimental" ~ "Vintage intermedio: indicadores experimentales/BCCh disponibles",
    stage == "eee" ~ "Vintage temprano: EEE y supuestos de corto plazo",
    TRUE ~ "Vintage inicial: supuestos de corto plazo"
  )
}

detect_imacec_stage <- function(Data_ine, periodo_objetivo) {
  ine_vars <- c("mineria", "manufactura", "comercio", "electricidad")
  experimental_vars <- c("venta_minorista", "monto_credito", "cantidad_credito", "uf")

  if (has_all_current(Data_ine, periodo_objetivo, ine_vars)) return("ine")
  if (has_any_current(Data_ine, periodo_objetivo, experimental_vars, min_available = 2L)) return("experimental")
  if (has_current_value(Data_ine, periodo_objetivo, "eee_imacec")) return("eee")
  "early"
}

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
      ref_period <- periodo_objetivo %m-% lubridate::months(lag_n)

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
          mean_last_non_na(n = 3)
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

run_nowcast <- function(model = c("auto", "ine", "experimental", "eee", "early"), assumptions = NULL) {
  model <- match.arg(model)
  cal_df <- read_calendar()
  Data_ine <- build_dataset_ine()
  periodo_objetivo <- get_target_period(Data_ine)
  last_obs <- last_observed_period(Data_ine)

  stage <- if (model == "auto") detect_imacec_stage(Data_ine, periodo_objetivo) else model

  if (stage == "ine") {
    fits <- fit_models_ine(Data_ine)
    Data <- Data_ine
  } else if (stage == "eee") {
    fits <- fit_models_eee(Data_ine)
    Data <- Data_ine
  } else {
    fits <- fit_models_experimental(Data_ine)
    Data <- Data_ine
    if (stage == "early") {
      fits$model_label <- "Modelo inicial con supuestos de corto plazo"
      fits$stage <- "early"
    }
  }

  Data_fit <- Data |>
    dplyr::mutate(
      imacec_fit = NA_real_,
      imacec_nm_fit = NA_real_
    )

  idx_total <- stats::complete.cases(stats::model.frame(fits$modelo_imacec, data = Data_fit, na.action = stats::na.pass))
  idx_nm <- stats::complete.cases(stats::model.frame(fits$modelo_imacec_nm, data = Data_fit, na.action = stats::na.pass))

  Data_fit$imacec_fit[idx_total] <- as.numeric(stats::predict(fits$modelo_imacec, newdata = Data_fit[idx_total, , drop = FALSE]))
  Data_fit$imacec_nm_fit[idx_nm] <- as.numeric(stats::predict(fits$modelo_imacec_nm, newdata = Data_fit[idx_nm, , drop = FALSE]))

  if (is.null(assumptions)) assumptions <- make_default_assumptions(Data, periodo_objetivo)
  assumptions_tbl <- get_assumptions_table(assumptions)

  newdata_imacec <- build_newdata_from_model(
    fits$modelo_imacec, periodo_objetivo, Data, cal_df, assumptions
  )

  newdata_imacec_nm <- build_newdata_from_model(
    fits$modelo_imacec_nm, periodo_objetivo, Data, cal_df, assumptions
  )

  pred_total <- predict_confint(fits$modelo_imacec, newdata_imacec)
  pred_nm    <- predict_confint(fits$modelo_imacec_nm, newdata_imacec_nm)

  eee_total <- current_value(Data, periodo_objetivo, "eee_imacec")
  eee_nm <- current_value(Data, periodo_objetivo, "eee_imacec_nm")

  proyeccion <- tibble::tibble(
    Periodo = periodo_objetivo,
    imacec_predicho = pred_total$fit,
    imacec_lwr = pred_total$lwr,
    imacec_upr = pred_total$upr,
    imacec_nm_predicho = pred_nm$fit,
    imacec_nm_lwr = pred_nm$lwr,
    imacec_nm_upr = pred_nm$upr,
    eee_imacec = eee_total,
    eee_imacec_nm = eee_nm,
    modelo = fits$model_label,
    vintage = stage,
    vintage_label = stage_label(stage),
    ultima_observacion_imacec = last_obs,
    fecha_actualizacion = Sys.Date(),
    fecha_hora_actualizacion = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  )

  update_status <- tibble::tibble(
    fecha_actualizacion = Sys.Date(),
    fecha_hora_actualizacion = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    ultima_observacion_imacec = last_obs,
    periodo_objetivo = periodo_objetivo,
    vintage = stage,
    vintage_label = stage_label(stage),
    modelo = fits$model_label,
    tiene_eee = !is.na(eee_total),
    tiene_experimentales = has_any_current(Data, periodo_objetivo, c("venta_minorista", "monto_credito", "cantidad_credito", "uf"), 2L),
    tiene_ine = has_all_current(Data, periodo_objetivo, c("mineria", "manufactura", "comercio", "electricidad"))
  )

  list(
    Data = Data_fit,
    modelo_imacec = fits$modelo_imacec,
    modelo_imacec_nm = fits$modelo_imacec_nm,
    proyeccion = proyeccion,
    newdata_imacec = newdata_imacec,
    newdata_imacec_nm = newdata_imacec_nm,
    assumptions = assumptions_tbl,
    update_status = update_status,
    model_label = fits$model_label,
    stage = stage
  )
}
