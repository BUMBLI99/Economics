# ============================================================
# imacec_data.R
# Descarga y preparación de base mensual IMACEC
# ============================================================

fetch_series_optional <- function(code, var_name = NULL, firstdate = first_date, lastdate = last_date) {
  tryCatch(
    fetch_series(code, firstdate = firstdate, lastdate = lastdate),
    error = function(e) {
      warning(
        "No se pudo descargar la serie opcional",
        if (!is.null(var_name)) paste0(" ", var_name) else "",
        ": ", conditionMessage(e),
        call. = FALSE
      )
      tibble::tibble(date = as.Date(character()), value = numeric())
    }
  )
}

get_eee_expectations <- function() {
  # La EEE reporta expectativas para el IMACEC de "un mes atrás".
  # Por eso una encuesta fechada en M se alinea al mes objetivo M-1.
  eee_series <- list(
    eee_imacec = codes$eee_imacec,
    eee_imacec_nm = codes$eee_imacec_nm
  )

  df_raw <- purrr::imap_dfr(eee_series, function(code, var_name) {
    fetch_series_optional(code, var_name = var_name) |>
      dplyr::mutate(var = var_name)
  })

  if (nrow(df_raw) == 0) {
    return(tibble::tibble(
      Periodo = as.Date(character()),
      eee_imacec = numeric(),
      eee_imacec_nm = numeric()
    ))
  }

  df_raw |>
    dplyr::filter(!is.na(date)) |>
    dplyr::mutate(Periodo = lubridate::floor_date(date, "month") %m-% lubridate::months(1)) |>
    dplyr::group_by(var, Periodo) |>
    dplyr::summarise(value = dplyr::last(value), .groups = "drop") |>
    tidyr::pivot_wider(names_from = var, values_from = value) |>
    dplyr::arrange(Periodo)
}

get_monthly_base <- function() {
  series_list <- list(
    imacec_nm_raw   = codes$imacec_nm,
    imacec_raw      = codes$imacec,
    venta_minorista = codes$ivdcm_yoy,
    monto_credito_raw = codes$credito_monto,
    cantidad_credito_raw = codes$credito_cant,
    desempleo       = codes$desempleo,
    cobre           = codes$cobre,
    petroleo        = codes$petroleo
  )

  base_raw <- purrr::imap_dfr(series_list, function(code, var_name) {
    fetch_series(code) |>
      dplyr::mutate(var = var_name)
  })

  if (nrow(base_raw) == 0) stop("No se pudo descargar la base mensual.")

  base_wide <- base_raw |>
    dplyr::mutate(Periodo = lubridate::floor_date(date, "month")) |>
    dplyr::group_by(var, Periodo) |>
    dplyr::summarise(value = dplyr::last(value), .groups = "drop") |>
    tidyr::pivot_wider(names_from = var, values_from = value) |>
    dplyr::arrange(Periodo)

  eee_df <- get_eee_expectations()

  out <- base_wide |>
    dplyr::mutate(
      imacec    = yoy(imacec_raw),
      imacec_nm = yoy(imacec_nm_raw),
      cobre_yoy = yoy(cobre),
      petroleo_yoy = yoy(petroleo),
      monto_credito = yoy(monto_credito_raw),
      cantidad_credito = yoy(cantidad_credito_raw)
    ) |>
    dplyr::select(
      Periodo,
      imacec,
      imacec_nm,
      venta_minorista,
      monto_credito,
      cantidad_credito,
      desempleo,
      cobre_yoy,
      petroleo_yoy
    ) |>
    dplyr::left_join(eee_df, by = "Periodo")

  if (!"eee_imacec" %in% names(out)) out$eee_imacec <- NA_real_
  if (!"eee_imacec_nm" %in% names(out)) out$eee_imacec_nm <- NA_real_

  out
}

get_uf_monthly <- function() {
  uf_d <- fetch_series(codes$uf_daily)
  if (nrow(uf_d) == 0) stop("No llegó UF desde BCCh.")

  uf_d |>
    dplyr::mutate(Periodo = lubridate::floor_date(date, "month")) |>
    dplyr::group_by(Periodo) |>
    dplyr::summarise(uf_nivel = value[which.max(date)], .groups = "drop") |>
    dplyr::arrange(Periodo) |>
    dplyr::mutate(uf = yoy(uf_nivel)) |>
    dplyr::select(Periodo, uf)
}

add_common_features <- function(df) {
  df |>
    dplyr::arrange(Periodo) |>
    dplyr::mutate(
      mes = factor(lubridate::month(Periodo), levels = 1:12),
      feb = as.integer(lubridate::month(Periodo) == 2),
      bisiesto = as.integer(lubridate::leap_year(Periodo)),
      dias_mes = as.numeric(lubridate::days_in_month(Periodo)),
      d_2022_04 = as.integer(Periodo == as.Date("2022-04-01")),
      d_2020_04 = as.integer(Periodo == as.Date("2020-04-01")),
      d_2020_05 = as.integer(Periodo == as.Date("2020-05-01")),
      d_2024_06 = as.integer(Periodo == as.Date("2024-06-01")),
      d_postCov = as.integer(Periodo >= as.Date("2022-01-01")),
      imacec_lag1 = dplyr::lag(imacec, 1),
      imacec_lag2 = dplyr::lag(imacec, 2),
      imacec_lag4 = dplyr::lag(imacec, 4),
      imacec_lag12 = dplyr::lag(imacec, 12),
      imacec_nm_lag1 = dplyr::lag(imacec_nm, 1),
      imacec_nm_lag2 = dplyr::lag(imacec_nm, 2),
      imacec_nm_lag4 = dplyr::lag(imacec_nm, 4),
      imacec_nm_lag12 = dplyr::lag(imacec_nm, 12),
      cobre_yoy_lag1 = dplyr::lag(cobre_yoy, 1),
      petroleo_yoy_lag1 = dplyr::lag(petroleo_yoy, 1),
      monto_credito_lag1 = dplyr::lag(monto_credito, 1),
      cantidad_credito_lag1 = dplyr::lag(cantidad_credito, 1),
      venta_minorista_lag1 = dplyr::lag(venta_minorista, 1),
      uf_lag1 = dplyr::lag(uf, 1),
      desempleo_lag1 = dplyr::lag(desempleo, 1),
      eee_imacec_lag1 = dplyr::lag(eee_imacec, 1),
      eee_imacec_nm_lag1 = dplyr::lag(eee_imacec_nm, 1),
      t = dplyr::row_number()
    )
}

build_dataset <- function() {
  cal_df <- read_calendar()

  get_monthly_base() |>
    dplyr::left_join(get_uf_monthly(), by = "Periodo") |>
    dplyr::left_join(cal_df, by = "Periodo") |>
    add_common_features()
}

get_ine_features <- function() {
  df_raw <- purrr::imap_dfr(codes_ine, function(code, var_name) {
    fetch_series(code, first_date, last_date) |>
      dplyr::mutate(var = var_name)
  })

  if (nrow(df_raw) == 0) stop("No llegaron series INE.")

  df_raw |>
    dplyr::mutate(Periodo = lubridate::floor_date(date, "month")) |>
    dplyr::group_by(var, Periodo) |>
    dplyr::summarise(nivel = dplyr::last(value), .groups = "drop") |>
    dplyr::group_by(var) |>
    dplyr::arrange(Periodo, .by_group = TRUE) |>
    dplyr::mutate(
      value = dplyr::case_when(
        var %in% c("mineria", "manufactura", "comercio", "electricidad") ~ yoy(nivel),
        var == "desempleo" ~ nivel,
        TRUE ~ nivel
      )
    ) |>
    dplyr::ungroup() |>
    dplyr::select(Periodo, var, value) |>
    tidyr::pivot_wider(names_from = var, values_from = value) |>
    dplyr::arrange(Periodo)
}

build_dataset_ine <- function() {
  data_base <- build_dataset()
  ine_df <- get_ine_features()

  vars_esperadas <- c("mineria", "manufactura", "comercio", "electricidad", "desempleo")
  for (v in vars_esperadas) {
    if (!v %in% names(ine_df)) ine_df[[v]] <- NA_real_
  }

  data_base |>
    dplyr::select(-dplyr::any_of(c("desempleo", "desempleo_lag1"))) |>
    dplyr::left_join(ine_df, by = "Periodo") |>
    dplyr::arrange(Periodo) |>
    dplyr::mutate(
      mineria_lag1      = dplyr::lag(mineria, 1),
      manufactura_lag1  = dplyr::lag(manufactura, 1),
      comercio_lag1     = dplyr::lag(comercio, 1),
      electricidad_lag1 = dplyr::lag(electricidad, 1),
      desempleo_lag1    = dplyr::lag(desempleo, 1)
    )
}
