# ============================================================
# imacec_outputs.R
# Vintages, evaluación y salidas del ciclo mensual
# ============================================================

empty_projection_table <- function() {
  tibble::tibble(
    Periodo = as.Date(character()), target_key = character(), variable = character(),
    corte = character(), model_key = character(), modelo = character(), estado = character(),
    forecast = numeric(), lwr = numeric(), upr = numeric(), nivel_intervalo = numeric(),
    eee_value = numeric(), eee_survey_period = as.Date(character()), observed = numeric(),
    fecha_actualizacion = as.Date(character()), run_timestamp = character()
  )
}

projection_rows <- function(results) {
  if (!length(results)) return(empty_projection_table())
  purrr::map_dfr(results, "proyeccion")
}

history_rows <- function(results, data) {
  actual <- purrr::imap_dfr(target_specs, function(spec, key) {
    data |>
      dplyr::filter(!is.na(.data[[spec$response]])) |>
      dplyr::transmute(
        Periodo, target_key = key, variable = spec$label,
        observed = .data[[spec$response]], fitted = NA_real_,
        model_key = "actual", modelo = "IMACEC efectivo", corte = "oficial", tipo = "Efectivo"
      )
  })
  fits <- if (length(results)) purrr::map_dfr(results, "history") else tibble::tibble()
  nowcasts <- if (length(results)) purrr::map_dfr(results, function(result) {
    p <- result$proyeccion
    p |>
      dplyr::transmute(
        Periodo, target_key, variable, observed, fitted = forecast,
        model_key, modelo, corte, tipo = "Nowcast"
      )
  }) else tibble::tibble()
  dplyr::bind_rows(actual, fits, nowcasts) |>
    dplyr::arrange(target_key, model_key, Periodo)
}

fit_metrics <- function(history) {
  history |>
    dplyr::filter(tipo == "Ajuste", !is.na(observed), !is.na(fitted)) |>
    dplyr::group_by(variable, modelo, model_key) |>
    dplyr::summarise(
      n = dplyr::n(), rmse = sqrt(mean((observed - fitted)^2)),
      mae = mean(abs(observed - fitted)), .groups = "drop"
    ) |>
    dplyr::mutate(nota = "Ajuste interno; no equivale a desempeño predictivo fuera de muestra.")
}

read_archive_safe <- function(path) {
  if (!file.exists(path)) return(NULL)
  old <- suppressMessages(readr::read_csv(path, show_col_types = FALSE))
  required <- c("Periodo", "target_key", "model_key", "forecast", "run_timestamp")
  if (!all(required %in% names(old))) {
    backup <- sub("[.]csv$", "_legacy.csv", path)
    if (!file.exists(backup)) file.copy(path, backup)
    return(NULL)
  }
  old |>
    dplyr::mutate(
      Periodo = as.Date(Periodo), fecha_actualizacion = as.Date(fecha_actualizacion),
      eee_survey_period = as.Date(eee_survey_period),
      dplyr::across(
        dplyr::any_of(c("forecast", "lwr", "upr", "nivel_intervalo", "eee_value", "observed")),
        ~ suppressWarnings(as.numeric(.x))
      ),
      dplyr::across(
        dplyr::any_of(c("target_key", "variable", "corte", "model_key", "modelo", "estado", "run_timestamp")),
        as.character
      )
    )
}

append_projection_archive <- function(projections, output_dir) {
  path <- file.path(output_dir, "imacec_projection_archive.csv")
  old <- read_archive_safe(path)
  active <- projections |>
    dplyr::filter(is.na(observed), model_key %in% c("proxy", "m4", "m8p"))
  combined <- dplyr::bind_rows(old, active)
  if (!nrow(combined)) {
    out <- empty_projection_table()
    readr::write_csv(out, path)
    return(out)
  }
  out <- combined |>
    dplyr::distinct(Periodo, target_key, model_key, run_timestamp, .keep_all = TRUE) |>
    dplyr::arrange(Periodo, target_key, model_key, run_timestamp)
  readr::write_csv(out, path)
  out
}

build_projection_evaluation <- function(archive, data, output_dir) {
  actual <- purrr::imap_dfr(target_specs, function(spec, key) {
    data |>
      dplyr::filter(!is.na(.data[[spec$response]])) |>
      dplyr::transmute(
        Periodo, target_key = key, observed_official = .data[[spec$response]]
      )
  })
  evaluation <- archive |>
    dplyr::left_join(actual, by = c("Periodo", "target_key")) |>
    dplyr::filter(!is.na(observed_official)) |>
    dplyr::mutate(
      error_modelo = observed_official - forecast,
      error_eee = ifelse(is.na(eee_value), NA_real_, observed_official - eee_value)
    ) |>
    dplyr::arrange(Periodo, target_key, model_key, run_timestamp)
  readr::write_csv(evaluation, file.path(output_dir, "imacec_projection_evaluation.csv"))
  evaluation
}

export_imacec_outputs <- function(results, data, eee, cycle,
                                  output_dir = "data/processed",
                                  fig_dir = "assets/img/imacec") {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

  projections <- projection_rows(results)
  history <- history_rows(results, data)
  metrics <- fit_metrics(history)
  oos <- compute_pseudo_oos(data)

  readr::write_csv(projections, file.path(output_dir, "imacec_projection_all_models.csv"))
  readr::write_csv(projections, file.path(output_dir, "imacec_projection.csv"))
  readr::write_csv(projections, file.path(output_dir, "imacec_nowcast_summary.csv"))
  readr::write_csv(history, file.path(output_dir, "imacec_nowcast_history_all_models.csv"))
  readr::write_csv(history, file.path(output_dir, "imacec_nowcast_history.csv"))
  readr::write_csv(metrics, file.path(output_dir, "imacec_model_metrics.csv"))
  readr::write_csv(cycle, file.path(output_dir, "imacec_update_status.csv"))
  readr::write_csv(oos$predictions, file.path(output_dir, "imacec_pseudo_oos_predictions.csv"))
  readr::write_csv(oos$metrics, file.path(output_dir, "imacec_pseudo_oos_metrics.csv"))
  readr::write_csv(eee, file.path(output_dir, "imacec_eee_aligned.csv"))

  archive <- append_projection_archive(projections, output_dir)
  evaluation <- build_projection_evaluation(archive, data, output_dir)

  invisible(list(
    projections = projections, history = history, metrics = metrics,
    status = cycle, oos = oos, archive = archive, evaluation = evaluation
  ))
}
