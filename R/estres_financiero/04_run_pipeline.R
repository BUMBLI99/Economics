# ============================================================
# 04_run_pipeline.R
# Pipeline completo del monitor de estrés financiero para Chile.
# ============================================================

run_estres_financiero_pipeline <- function(root = estres_project_root(),
                                           use_live = estres_api_config()$use_live,
                                           fallback_to_local = estres_api_config()$fallback_to_local,
                                           start_date = Sys.getenv("ESTRES_START_DATE", unset = "2010-01-01"),
                                           end_date = format(Sys.Date(), "%Y-%m-%d")) {
  estres_load_packages()
  estres_make_dirs(root)

  raw <- estres_get_raw_market_data(
    root = root,
    use_live = use_live,
    fallback_to_local = fallback_to_local,
    start_date = start_date,
    end_date = end_date
  )

  market_data <- estres_prepare_market_data(raw)
  estres_write_market_data(market_data, root = root)

  fx_fit <- estres_estimate_fx_model(market_data)
  y10_fit <- estres_estimate_y10_model(market_data)
  index_data <- estres_construct_index(fx_fit, y10_fit)

  oos_index <- tryCatch(
    estres_construct_oos_index(market_data, min_obs = 500, step = 5),
    error = function(e) {
      warning("No se pudo construir el índice pseudo out-of-sample: ", conditionMessage(e))
      tibble::tibble()
    }
  )

  estres_write_outputs(index_data, fx_fit, y10_fit, root = root, oos_index = oos_index)
  estres_save_figures(index_data, root = root)

  latest <- index_data |>
    dplyr::filter(
      !is.na(.data$stress_market),
      !is.na(.data$stress_market_30d),
      !is.na(.data$z_fx),
      !is.na(.data$z_y10)
    ) |>
    dplyr::slice_tail(n = 1)

  source_log_file <- file.path(root, "data/processed/estres_financiero/data_update_log.csv")
  source_label <- if (file.exists(source_log_file)) {
    readr::read_csv(source_log_file, show_col_types = FALSE) |>
      dplyr::slice_tail(n = 1) |>
      dplyr::pull(.data$source)
  } else {
    "sin registro"
  }

  message("Pipeline terminado.")
  message("Fuente efectiva: ", source_label)
  message("Última observación completa: ", as.character(latest$date[[1]]))
  message("Índice 30d: ", round(latest$stress_market_30d[[1]], 3), " | Régimen: ", latest$regime[[1]])
  if (exists("oos_index") && nrow(oos_index) > 0) {
    message("Índice pseudo out-of-sample generado: data/processed/estres_financiero/stress_index_chile_oos.csv")
  }
  message("Predictores FX usados: ", paste(fx_fit$predictors, collapse = ", "))
  message("Predictores 10Y usados: ", paste(y10_fit$predictors, collapse = ", "))

  invisible(list(
    raw = raw,
    market_data = market_data,
    fx_fit = fx_fit,
    y10_fit = y10_fit,
    index_data = index_data,
    oos_index = oos_index,
    latest = latest
  ))
}
