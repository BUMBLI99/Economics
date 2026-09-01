# ============================================================
# imacec_outputs.R
# Salidas reproducibles y gráficos por corte
# ============================================================

projection_rows <- function(results) purrr::map_dfr(results, "proyeccion")

history_rows <- function(results, eee) {
  actual <- results[[1]]$Data |>
    dplyr::select(Periodo, imacec) |>
    dplyr::distinct(Periodo, .keep_all = TRUE)

  purrr::map_dfr(results, function(result) {
    target <- result$proyeccion$Periodo[1]
    projection <- tibble::tibble(
      Periodo = target,
      imacec = result$proyeccion$imacec_observado[1],
      imacec_fit = result$proyeccion$imacec_predicho[1],
      model_key = result$model_key,
      modelo = result$model_label,
      corte = result$corte,
      tipo = "Nowcast"
    )
    dplyr::bind_rows(result$history, projection) |>
      dplyr::left_join(actual, by = "Periodo", suffix = c("", "_actual")) |>
      dplyr::mutate(imacec = dplyr::coalesce(imacec_actual, imacec)) |>
      dplyr::select(-imacec_actual) |>
      dplyr::left_join(eee |> dplyr::select(Periodo, eee_imacec, eee_survey_period = survey_period), by = "Periodo")
  }) |>
    dplyr::arrange(corte, Periodo)
}

fit_metrics <- function(results) {
  purrr::map_dfr(results, function(result) {
    d <- result$history |> dplyr::filter(!is.na(imacec), !is.na(imacec_fit))
    tibble::tibble(
      variable = "IMACEC total",
      modelo = result$model_label,
      model_key = result$model_key,
      corte = result$corte,
      n = nrow(d),
      rmse = sqrt(mean((d$imacec - d$imacec_fit)^2)),
      mae = mean(abs(d$imacec - d$imacec_fit)),
      nota = "Ajuste interno; no equivale a desempeño predictivo fuera de muestra."
    )
  })
}

status_rows <- function(results) {
  purrr::map_dfr(results, function(result) {
    p <- result$proyeccion
    last_obs <- result$Data |>
      dplyr::filter(!is.na(imacec)) |>
      dplyr::summarise(value = max(Periodo)) |>
      dplyr::pull(value)
    tibble::tibble(
      fecha_actualizacion = Sys.Date(),
      fecha_hora_actualizacion = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
      corte = result$corte,
      model_key = result$model_key,
      modelo = result$model_label,
      periodo_objetivo = p$Periodo[1],
      ultima_observacion_imacec = last_obs,
      estado = p$estado[1],
      tiene_eee = !is.na(p$eee_imacec[1]),
      eee_survey_period = p$eee_survey_period[1]
    )
  })
}

append_projection_archive <- function(projections, output_dir) {
  path <- file.path(output_dir, "imacec_projection_archive.csv")
  old <- if (file.exists(path)) suppressMessages(readr::read_csv(path, show_col_types = FALSE)) else NULL
  required <- names(projections)
  if (!is.null(old) && !all(required %in% names(old))) {
    backup <- sub("\\.csv$", "_legacy.csv", path)
    if (!file.exists(backup)) file.copy(path, backup)
    old <- NULL
  }
  out <- dplyr::bind_rows(old, projections) |>
    dplyr::distinct(fecha_actualizacion, Periodo, model_key, .keep_all = TRUE) |>
    dplyr::arrange(Periodo, model_key, fecha_actualizacion)
  readr::write_csv(out, path)
  out
}

build_projection_evaluation <- function(archive, data, output_dir) {
  observed <- data |>
    dplyr::filter(!is.na(imacec)) |>
    dplyr::select(Periodo, imacec_observado = imacec)
  evaluation <- archive |>
    dplyr::select(Periodo, fecha_actualizacion, corte, model_key, modelo, imacec_predicho, eee_imacec) |>
    dplyr::left_join(observed, by = "Periodo") |>
    dplyr::filter(!is.na(imacec_observado)) |>
    dplyr::mutate(
      error_modelo = imacec_observado - imacec_predicho,
      error_eee = ifelse(is.na(eee_imacec), NA_real_, imacec_observado - eee_imacec)
    )
  readr::write_csv(evaluation, file.path(output_dir, "imacec_projection_evaluation.csv"))
  evaluation
}

plot_cutoff <- function(history, model_key, months = 96) {
  d <- history |>
    dplyr::filter(model_key == !!model_key) |>
    dplyr::filter(Periodo >= max(Periodo, na.rm = TRUE) %m-% lubridate::months(months))
  label <- unique(d$modelo)[1]
  ggplot2::ggplot(d, ggplot2::aes(Periodo)) +
    ggplot2::geom_hline(yintercept = 0, linewidth = .3, color = "grey72") +
    ggplot2::geom_line(ggplot2::aes(y = imacec, color = "IMACEC efectivo"), linewidth = .9, na.rm = TRUE) +
    ggplot2::geom_line(ggplot2::aes(y = imacec_fit, color = label), linewidth = .8, linetype = "dashed", na.rm = TRUE) +
    ggplot2::geom_point(
      data = dplyr::filter(d, tipo == "Nowcast"),
      ggplot2::aes(y = imacec_fit, color = label), size = 3, na.rm = TRUE
    ) +
    ggplot2::geom_point(ggplot2::aes(y = eee_imacec, color = "EEE alineada a M-1"), shape = 4, size = 2.5, na.rm = TRUE) +
    ggplot2::scale_color_manual(values = c(
      "IMACEC efectivo" = "#17344d", "EEE alineada a M-1" = "#c08a24",
      stats::setNames(if (model_key == "m4") "#c24f32" else "#167b7d", label)
    )) +
    ggplot2::labs(
      title = paste0("IMACEC · ", label),
      subtitle = "Variación interanual; la EEE publicada en M se compara con el IMACEC de M-1",
      x = NULL, y = "Variación 12 meses (%)", color = NULL
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(legend.position = "bottom", panel.grid.minor = ggplot2::element_blank())
}

export_imacec_outputs <- function(results, eee, output_dir = "data/processed", fig_dir = "assets/img/imacec") {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

  projections <- projection_rows(results)
  history <- history_rows(results, eee)
  metrics <- fit_metrics(results)
  status <- status_rows(results)
  oos <- compute_pseudo_oos(results[[1]]$Data)

  readr::write_csv(projections, file.path(output_dir, "imacec_projection_all_models.csv"))
  readr::write_csv(projections, file.path(output_dir, "imacec_projection.csv"))
  readr::write_csv(history, file.path(output_dir, "imacec_nowcast_history_all_models.csv"))
  readr::write_csv(history, file.path(output_dir, "imacec_nowcast_history.csv"))
  readr::write_csv(metrics, file.path(output_dir, "imacec_model_metrics.csv"))
  readr::write_csv(status, file.path(output_dir, "imacec_update_status.csv"))
  readr::write_csv(oos$predictions, file.path(output_dir, "imacec_pseudo_oos_predictions.csv"))
  readr::write_csv(oos$metrics, file.path(output_dir, "imacec_pseudo_oos_metrics.csv"))
  readr::write_csv(eee, file.path(output_dir, "imacec_eee_aligned.csv"))

  summary <- projections |>
    dplyr::select(Periodo, corte, modelo, imacec_predicho, imacec_lwr, imacec_upr, eee_imacec, eee_survey_period)
  readr::write_csv(summary, file.path(output_dir, "imacec_nowcast_summary.csv"))

  archive <- append_projection_archive(projections, output_dir)
  evaluation <- build_projection_evaluation(archive, results[[1]]$Data, output_dir)

  plots <- purrr::imap(results, function(result, key) plot_cutoff(history, key))
  purrr::iwalk(plots, function(plot, key) {
    ggplot2::ggsave(file.path(fig_dir, paste0("imacec_", key, "_nowcast.png")), plot, width = 10, height = 6.2, dpi = 180)
  })

  invisible(list(
    projections = projections, history = history, metrics = metrics, status = status,
    oos = oos, archive = archive, evaluation = evaluation, plots = plots
  ))
}
