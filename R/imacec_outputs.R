# ============================================================
# imacec_outputs.R
# Tablas, métricas, gráficos, archivo de vintages y exportación
# ============================================================

make_summary_table <- function(resultado) {
  ultimos_obs <- resultado$Data |>
    dplyr::filter(!is.na(imacec), !is.na(imacec_nm)) |>
    dplyr::arrange(dplyr::desc(Periodo)) |>
    dplyr::slice_head(n = 5) |>
    dplyr::arrange(Periodo) |>
    dplyr::transmute(
      Periodo,
      IMACEC = round(imacec, 2),
      IMACEC_no_minero = round(imacec_nm, 2),
      Proyeccion_EEE = round(eee_imacec, 2),
      Tipo = "Observado"
    )

  fila_proj <- resultado$proyeccion |>
    dplyr::transmute(
      Periodo,
      IMACEC = round(imacec_predicho, 2),
      IMACEC_no_minero = round(imacec_nm_predicho, 2),
      Proyeccion_EEE = round(eee_imacec, 2),
      Tipo = "Nowcast vigente"
    )

  dplyr::bind_rows(ultimos_obs, fila_proj)
}

make_history_table <- function(resultado) {
  proy <- resultado$proyeccion

  hist <- resultado$Data |>
    dplyr::select(
      Periodo,
      imacec,
      imacec_nm,
      imacec_fit,
      imacec_nm_fit,
      eee_imacec,
      eee_imacec_nm
    ) |>
    dplyr::mutate(tipo = "Histórico")

  proj_row <- tibble::tibble(
    Periodo = proy$Periodo,
    imacec = NA_real_,
    imacec_nm = NA_real_,
    imacec_fit = proy$imacec_predicho,
    imacec_nm_fit = proy$imacec_nm_predicho,
    eee_imacec = proy$eee_imacec,
    eee_imacec_nm = proy$eee_imacec_nm,
    tipo = "Nowcast"
  )

  dplyr::bind_rows(hist, proj_row) |>
    dplyr::arrange(Periodo)
}

compute_fit_metrics <- function(resultado) {
  d <- resultado$Data

  metric_one <- function(obs, fit) {
    ok <- !is.na(obs) & !is.na(fit)
    tibble::tibble(
      n = sum(ok),
      rmse = sqrt(mean((obs[ok] - fit[ok])^2)),
      mae = mean(abs(obs[ok] - fit[ok]))
    )
  }

  dplyr::bind_rows(
    metric_one(d$imacec, d$imacec_fit) |>
      dplyr::mutate(variable = "IMACEC total"),
    metric_one(d$imacec_nm, d$imacec_nm_fit) |>
      dplyr::mutate(variable = "IMACEC no minero")
  ) |>
    dplyr::select(variable, n, rmse, mae) |>
    dplyr::mutate(
      rmse = round(rmse, 2),
      mae = round(mae, 2),
      nota = "Métricas in-sample; no interpretar como evaluación fuera de muestra."
    )
}

make_projection_archive <- function(resultado, output_dir = "data/processed") {
  archive_path <- file.path(output_dir, "imacec_projection_archive.csv")
  old <- if (file.exists(archive_path)) {
    readr::read_csv(archive_path, show_col_types = FALSE) |>
      dplyr::mutate(
        Periodo = as.Date(Periodo),
        fecha_actualizacion = as.Date(fecha_actualizacion),
        ultima_observacion_imacec = as.Date(ultima_observacion_imacec)
      )
  } else {
    tibble::tibble()
  }

  new <- resultado$proyeccion |>
    dplyr::transmute(
      fecha_actualizacion,
      fecha_hora_actualizacion,
      Periodo,
      ultima_observacion_imacec,
      vintage,
      vintage_label,
      modelo,
      imacec_predicho,
      imacec_nm_predicho,
      eee_imacec,
      eee_imacec_nm
    )

  dplyr::bind_rows(old, new) |>
    dplyr::arrange(Periodo, fecha_actualizacion, fecha_hora_actualizacion) |>
    dplyr::distinct(Periodo, fecha_actualizacion, vintage, .keep_all = TRUE)
}

make_projection_evaluation <- function(resultado, archive) {
  if (nrow(archive) == 0) {
    return(tibble::tibble())
  }

  obs <- resultado$Data |>
    dplyr::filter(!is.na(imacec)) |>
    dplyr::select(Periodo, imacec, imacec_nm)

  archive |>
    dplyr::left_join(obs, by = "Periodo") |>
    dplyr::filter(!is.na(imacec)) |>
    dplyr::group_by(Periodo) |>
    dplyr::arrange(dplyr::desc(fecha_actualizacion), .by_group = TRUE) |>
    dplyr::slice_head(n = 1) |>
    dplyr::ungroup() |>
    dplyr::transmute(
      Periodo,
      fecha_proyeccion = fecha_actualizacion,
      vintage,
      modelo,
      imacec_observado = imacec,
      imacec_predicho,
      error_imacec = imacec - imacec_predicho,
      eee_imacec,
      error_eee = imacec - eee_imacec,
      imacec_nm_observado = imacec_nm,
      imacec_nm_predicho,
      error_imacec_nm = imacec_nm - imacec_nm_predicho
    ) |>
    dplyr::arrange(dplyr::desc(Periodo))
}

plot_nowcast <- function(resultado, variable = c("total", "no_minero"), ultimos_meses = 96) {
  variable <- match.arg(variable)
  history <- make_history_table(resultado)

  if (!is.null(ultimos_meses)) {
    fecha_min <- max(history$Periodo, na.rm = TRUE) %m-% lubridate::period(num = ultimos_meses - 1, units = "month")
    history <- history |>
      dplyr::filter(Periodo >= fecha_min)
  }

  periodo_objetivo <- resultado$proyeccion$Periodo[1]
  title_month <- month_label_es(periodo_objetivo)

  if (variable == "total") {
    y_obs <- "imacec"
    y_fit <- "imacec_fit"
    y_eee <- "eee_imacec"
    y_label <- "IMACEC total, var. 12m (%)"
    title <- paste0("Nowcast IMACEC total: ", title_month)
  } else {
    y_obs <- "imacec_nm"
    y_fit <- "imacec_nm_fit"
    y_eee <- "eee_imacec_nm"
    y_label <- "IMACEC no minero, var. 12m (%)"
    title <- paste0("Nowcast IMACEC no minero: ", title_month)
  }

  nowcast_row <- dplyr::filter(history, tipo == "Nowcast")

  ggplot2::ggplot(history, ggplot2::aes(x = Periodo)) +
    ggplot2::geom_hline(yintercept = 0, linewidth = 0.25, color = "grey70") +
    ggplot2::geom_line(ggplot2::aes(y = .data[[y_obs]], color = "Observado"), linewidth = 0.75, na.rm = TRUE) +
    ggplot2::geom_line(ggplot2::aes(y = .data[[y_fit]], color = "Ajuste del modelo"), linewidth = 0.75, linetype = "dashed", na.rm = TRUE) +
    ggplot2::geom_point(
      data = nowcast_row,
      ggplot2::aes(y = .data[[y_fit]], color = "Nowcast propio"),
      size = 2.8,
      na.rm = TRUE
    ) +
    ggplot2::geom_point(
      data = nowcast_row |> dplyr::filter(!is.na(.data[[y_eee]])),
      ggplot2::aes(y = .data[[y_eee]], color = "EEE"),
      size = 2.8,
      shape = 17,
      na.rm = TRUE
    ) +
    ggplot2::scale_color_manual(
      values = c(
        "Observado" = "#1f4e79",
        "Ajuste del modelo" = "#b03a2e",
        "Nowcast propio" = "#7f1d1d",
        "EEE" = "#7a5195"
      )
    ) +
    ggplot2::labs(
      title = title,
      subtitle = resultado$proyeccion$vintage_label[1],
      x = NULL,
      y = y_label,
      color = NULL
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      legend.position = "bottom",
      legend.direction = "horizontal",
      legend.title = ggplot2::element_blank(),
      plot.title = ggplot2::element_text(
        face = "bold",
        margin = ggplot2::margin(b = 12)
      ),
      panel.grid.minor = ggplot2::element_blank()
    )
}

compute_pseudo_oos_metrics <- function(resultado,
                                        min_train = 60,
                                        start_fraction = 0.65) {
  eval_one <- function(data, model, target, lag1_var, variable_label) {
    data <- data |>
      dplyr::arrange(.data$Periodo) |>
      dplyr::filter(!is.na(.data[[target]]))

    n <- nrow(data)
    if (n < min_train + 12) {
      return(tibble::tibble(
        variable = character(), modelo = character(), n = integer(),
        rmse = numeric(), mae = numeric(), inicio = as.Date(character()),
        fin = as.Date(character()), nota = character()
      ))
    }

    start_i <- max(min_train + 1L, ceiling(n * start_fraction))
    formula_main <- stats::formula(model)
    preds <- vector("list", n - start_i + 1L)

    for (i in seq(from = start_i, to = n)) {
      train <- data[seq_len(i - 1L), , drop = FALSE]
      test  <- data[i, , drop = FALSE]

      pred_model <- tryCatch({
        fit_i <- stats::lm(formula_main, data = train)
        as.numeric(stats::predict(fit_i, newdata = test))
      }, error = function(e) NA_real_)

      pred_ar1 <- tryCatch({
        if (!lag1_var %in% names(train)) {
          NA_real_
        } else {
          fit_ar <- stats::lm(stats::as.formula(paste(target, "~", lag1_var)), data = train)
          as.numeric(stats::predict(fit_ar, newdata = test))
        }
      }, error = function(e) NA_real_)

      hist_y <- train[[target]]
      pred_ma3 <- mean(utils::tail(hist_y[!is.na(hist_y)], 3), na.rm = TRUE)
      pred_seasonal <- if (i > 12) data[[target]][i - 12L] else NA_real_

      preds[[i - start_i + 1L]] <- tibble::tibble(
        Periodo = test$Periodo[[1]],
        observado = test[[target]][[1]],
        `Modelo principal` = pred_model,
        `Benchmark AR(1)` = pred_ar1,
        `Promedio móvil 3m` = pred_ma3,
        `Naive estacional t-12` = pred_seasonal
      )
    }

    pred_tbl <- dplyr::bind_rows(preds) |>
      tidyr::pivot_longer(
        cols = -c(Periodo, observado),
        names_to = "modelo",
        values_to = "predicho"
      ) |>
      dplyr::filter(!is.na(.data$observado), !is.na(.data$predicho))

    pred_tbl |>
      dplyr::group_by(.data$modelo) |>
      dplyr::summarise(
        n = dplyr::n(),
        rmse = sqrt(mean((.data$observado - .data$predicho)^2, na.rm = TRUE)),
        mae = mean(abs(.data$observado - .data$predicho), na.rm = TRUE),
        inicio = min(.data$Periodo, na.rm = TRUE),
        fin = max(.data$Periodo, na.rm = TRUE),
        .groups = "drop"
      ) |>
      dplyr::mutate(
        variable = variable_label,
        rmse = round(.data$rmse, 2),
        mae = round(.data$mae, 2),
        nota = "Pseudo out-of-sample con ventana expansiva; menor RMSE/MAE indica mejor desempeño predictivo."
      ) |>
      dplyr::select(variable, modelo, n, rmse, mae, inicio, fin, nota) |>
      dplyr::arrange(.data$variable, .data$rmse)
  }

  dplyr::bind_rows(
    eval_one(
      resultado$Data,
      resultado$modelo_imacec,
      target = "imacec",
      lag1_var = "imacec_lag1",
      variable_label = "IMACEC total"
    ),
    eval_one(
      resultado$Data,
      resultado$modelo_imacec_nm,
      target = "imacec_nm",
      lag1_var = "imacec_nm_lag1",
      variable_label = "IMACEC no minero"
    )
  )
}

export_imacec_outputs <- function(resultado,
                                  output_dir = "data/processed",
                                  fig_dir = "assets/img/imacec",
                                  ultimos_meses = 96) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

  history <- make_history_table(resultado)
  summary_tbl <- make_summary_table(resultado)
  metrics <- compute_fit_metrics(resultado)
  oos_metrics <- compute_pseudo_oos_metrics(resultado)
  archive <- make_projection_archive(resultado, output_dir = output_dir)
  evaluation <- make_projection_evaluation(resultado, archive)

  readr::write_csv(history, file.path(output_dir, "imacec_nowcast_history.csv"))
  readr::write_csv(summary_tbl, file.path(output_dir, "imacec_nowcast_summary.csv"))
  readr::write_csv(metrics, file.path(output_dir, "imacec_model_metrics.csv"))
  readr::write_csv(oos_metrics, file.path(output_dir, "imacec_oos_metrics.csv"))
  readr::write_csv(resultado$proyeccion, file.path(output_dir, "imacec_projection.csv"))
  readr::write_csv(resultado$update_status, file.path(output_dir, "imacec_update_status.csv"))
  readr::write_csv(resultado$assumptions, file.path(output_dir, "imacec_assumptions.csv"))
  readr::write_csv(archive, file.path(output_dir, "imacec_projection_archive.csv"))
  readr::write_csv(evaluation, file.path(output_dir, "imacec_projection_evaluation.csv"))

  g_total <- plot_nowcast(resultado, "total", ultimos_meses)
  g_nm <- plot_nowcast(resultado, "no_minero", ultimos_meses)

  ggplot2::ggsave(file.path(fig_dir, "imacec_total_nowcast.png"), g_total, width = 10, height = 6, dpi = 320)
  ggplot2::ggsave(file.path(fig_dir, "imacec_no_minero_nowcast.png"), g_nm, width = 10, height = 6, dpi = 320)

  invisible(list(
    history = history,
    summary = summary_tbl,
    metrics = metrics,
    oos_metrics = oos_metrics,
    archive = archive,
    evaluation = evaluation,
    g_total = g_total,
    g_nm = g_nm
  ))
}
