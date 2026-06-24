# ============================================================
# imacec_outputs.R
# Tablas, métricas, gráficos y exportación de resultados
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
      Tipo = "Observado",
      Modelo = NA_character_
    )

  fila_proj <- resultado$proyeccion |>
    dplyr::transmute(
      Periodo,
      IMACEC = round(imacec_predicho, 2),
      IMACEC_no_minero = round(imacec_nm_predicho, 2),
      Tipo = "Nowcast",
      Modelo = modelo
    )

  dplyr::bind_rows(ultimos_obs, fila_proj)
}

make_history_table <- function(resultado) {
  proy <- resultado$proyeccion
  fit_label <- if (!is.null(resultado$fit_model_label)) resultado$fit_model_label else resultado$model_label
  fit_key <- if (!is.null(resultado$fit_model_key)) resultado$fit_model_key else resultado$model_key

  hist <- resultado$Data |>
    dplyr::select(Periodo, imacec, imacec_nm, imacec_fit, imacec_nm_fit) |>
    dplyr::mutate(
      tipo = "Histórico",
      modelo = fit_label,
      model_key = fit_key
    )

  proj_row <- tibble::tibble(
    Periodo = proy$Periodo,
    imacec = NA_real_,
    imacec_nm = NA_real_,
    imacec_fit = proy$imacec_predicho,
    imacec_nm_fit = proy$imacec_nm_predicho,
    tipo = "Nowcast",
    modelo = proy$modelo,
    model_key = proy$model_key
  )

  dplyr::bind_rows(hist, proj_row) |>
    dplyr::arrange(Periodo)
}

make_history_table_all_models <- function(resultados) {
  purrr::imap_dfr(resultados, function(res, key) {
    if (is.null(res)) return(NULL)
    make_history_table(res)
  }) |>
    dplyr::arrange(modelo, Periodo)
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
    dplyr::mutate(
      modelo = resultado$model_label,
      nota = "Ajuste interno; no interpretar como desempeño predictivo fuera de muestra."
    ) |>
    dplyr::select(variable, modelo, n, rmse, mae, nota)
}

compute_fit_metrics_all <- function(resultados) {
  purrr::imap_dfr(resultados, function(res, key) {
    if (is.null(res)) return(NULL)
    compute_fit_metrics(res)
  })
}

# -------------------------------------------------------------------
# Evaluación pseudo out-of-sample
# -------------------------------------------------------------------

fit_for_key <- function(model_key, Data_train) {
  if (model_key == "base") fit_models_base(Data_train) else fit_models_ine(Data_train)
}

build_dataset_for_key <- function(model_key) {
  if (model_key == "base") build_dataset() else build_dataset_ine()
}

pseudo_oos_model_predictions <- function(model_key, variable = c("imacec", "imacec_nm"), eval_start_date) {
  variable <- match.arg(variable)
  Data_full <- build_dataset_for_key(model_key)
  cal_df <- read_calendar()

  periodos <- Data_full |>
    dplyr::filter(Periodo >= eval_start_date, !is.na(.data[[variable]])) |>
    dplyr::arrange(Periodo) |>
    dplyr::pull(Periodo)

  purrr::map_dfr(periodos, function(p) {
    tryCatch({
      Data_train <- Data_full |>
        dplyr::filter(Periodo < p)

      fits <- fit_for_key(model_key, Data_train)
      modelo <- if (variable == "imacec") fits$modelo_imacec else fits$modelo_imacec_nm

      newdata <- build_newdata_oos_from_model(
        modelo = modelo,
        periodo_objetivo = p,
        Data_train = Data_train,
        Data_available = Data_full,
        cal_df = cal_df,
        assumptions = make_default_assumptions(Data_train, periodo_objetivo = p)
      )

      pred <- as.numeric(stats::predict(modelo, newdata = newdata))
      obs <- Data_full |>
        dplyr::filter(Periodo == p) |>
        dplyr::pull(.data[[variable]])

      tibble::tibble(
        Periodo = p,
        variable = ifelse(variable == "imacec", "IMACEC total", "IMACEC no minero"),
        modelo = model_label_from_key(model_key),
        observado = as.numeric(obs[1]),
        predicho = pred
      )
    }, error = function(e) {
      NULL
    })
  })
}

pseudo_oos_benchmark_predictions <- function(Data_full, variable = c("imacec", "imacec_nm"), eval_start_date) {
  variable <- match.arg(variable)
  variable_label <- ifelse(variable == "imacec", "IMACEC total", "IMACEC no minero")

  periodos <- Data_full |>
    dplyr::filter(Periodo >= eval_start_date, !is.na(.data[[variable]])) |>
    dplyr::arrange(Periodo) |>
    dplyr::pull(Periodo)

  purrr::map_dfr(periodos, function(p) {
    train <- Data_full |>
      dplyr::filter(Periodo < p, !is.na(.data[[variable]])) |>
      dplyr::arrange(Periodo)

    if (nrow(train) < 13) return(NULL)

    obs <- Data_full |>
      dplyr::filter(Periodo == p) |>
      dplyr::pull(.data[[variable]])

    last_3 <- train |>
      dplyr::slice_tail(n = 3) |>
      dplyr::pull(.data[[variable]])

    lag12 <- Data_full |>
      dplyr::filter(Periodo == p %m-% months(12)) |>
      dplyr::pull(.data[[variable]])

    ar_data <- train |>
      dplyr::mutate(y_lag1 = dplyr::lag(.data[[variable]], 1)) |>
      tidyr::drop_na(.data[[variable]], y_lag1)

    ar_pred <- NA_real_
    if (nrow(ar_data) >= 24) {
      ar_fit <- stats::lm(stats::as.formula(paste0(variable, " ~ y_lag1")), data = ar_data)
      x_lag <- train |>
        dplyr::slice_tail(n = 1) |>
        dplyr::pull(.data[[variable]])
      ar_pred <- as.numeric(stats::predict(ar_fit, newdata = data.frame(y_lag1 = x_lag)))
    }

    tibble::tibble(
      Periodo = p,
      variable = variable_label,
      modelo = c("Benchmark AR(1)", "Promedio móvil 3m", "Naive estacional t-12"),
      observado = as.numeric(obs[1]),
      predicho = c(ar_pred, mean(last_3, na.rm = TRUE), as.numeric(lag12[1]))
    )
  })
}

summarise_oos_predictions <- function(preds, eval_start_date) {
  preds |>
    dplyr::filter(!is.na(observado), !is.na(predicho)) |>
    dplyr::group_by(variable, modelo) |>
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
      eval_start = eval_start_date,
      nota = "Pseudo-OOS recursivo; usa información final disponible, no vintages en tiempo real."
    ) |>
    dplyr::select(variable, modelo, N, RMSE, MAE, Periodo, eval_start, nota) |>
    dplyr::arrange(variable, RMSE)
}

compute_pseudo_oos_metrics <- function(eval_start_date = as.Date(Sys.getenv("IMACEC_EVAL_START_DATE", unset = "2021-01-01")), models = c("base", "ine")) {
  eval_start_date <- as.Date(eval_start_date)

  model_preds <- purrr::map_dfr(models, function(m) {
    dplyr::bind_rows(
      pseudo_oos_model_predictions(m, "imacec", eval_start_date),
      pseudo_oos_model_predictions(m, "imacec_nm", eval_start_date)
    )
  })

  # Benchmarks sobre la base común sin indicadores sectoriales INE.
  Data_base <- build_dataset()
  bench_preds <- dplyr::bind_rows(
    pseudo_oos_benchmark_predictions(Data_base, "imacec", eval_start_date),
    pseudo_oos_benchmark_predictions(Data_base, "imacec_nm", eval_start_date)
  )

  preds <- dplyr::bind_rows(model_preds, bench_preds)

  list(
    predictions = preds,
    metrics = summarise_oos_predictions(preds, eval_start_date)
  )
}

# -------------------------------------------------------------------
# Gráficos exportados como PNG
# -------------------------------------------------------------------

plot_nowcast <- function(resultado, variable = c("total", "no_minero"), ultimos_meses = 96) {
  variable <- match.arg(variable)
  d <- make_history_table(resultado) |>
    dplyr::filter(Periodo >= max(Periodo, na.rm = TRUE) %m-% months(ultimos_meses))

  if (variable == "total") {
    obs_col <- "imacec"
    fit_col <- "imacec_fit"
    ttl <- "IMACEC total: observado versus ajuste/nowcast"
  } else {
    obs_col <- "imacec_nm"
    fit_col <- "imacec_nm_fit"
    ttl <- "IMACEC no minero: observado versus ajuste/nowcast"
  }

  ggplot2::ggplot(d, ggplot2::aes(x = Periodo)) +
    ggplot2::geom_hline(yintercept = 0, linewidth = 0.25, color = "grey70") +
    ggplot2::geom_line(ggplot2::aes(y = .data[[obs_col]], color = "Observado"), linewidth = 0.85, na.rm = TRUE) +
    ggplot2::geom_line(ggplot2::aes(y = .data[[fit_col]], color = "Ajuste / nowcast"), linewidth = 0.85, linetype = "dashed", na.rm = TRUE) +
    ggplot2::geom_point(
      data = dplyr::filter(d, tipo == "Nowcast"),
      ggplot2::aes(y = .data[[fit_col]], color = "Nowcast"),
      size = 2.8,
      na.rm = TRUE
    ) +
    ggplot2::scale_color_manual(values = c("Observado" = "#1f4e79", "Ajuste / nowcast" = "#b03a2e", "Nowcast" = "#7f1d1d")) +
    ggplot2::scale_y_continuous(breaks = scales::breaks_width(5)) +
    ggplot2::labs(
      x = NULL,
      y = "Var. 12m (%)",
      color = NULL,
      title = ttl,
      subtitle = paste0("Modelo activo: ", resultado$model_label)
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      legend.position = "bottom",
      legend.direction = "horizontal",
      legend.title = ggplot2::element_blank(),
      plot.title = ggplot2::element_text(face = "bold", margin = ggplot2::margin(b = 6)),
      plot.subtitle = ggplot2::element_text(color = "#5B677A", margin = ggplot2::margin(b = 12)),
      panel.grid.minor = ggplot2::element_blank()
    )
}

export_imacec_outputs <- function(resultado,
                                  all_results = list(base = NULL, ine = NULL),
                                  output_dir = "data/processed",
                                  fig_dir = "assets/img/imacec",
                                  ultimos_meses = 96,
                                  eval_start_date = as.Date(Sys.getenv("IMACEC_EVAL_START_DATE", unset = "2021-01-01"))) {
  if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)
  if (!dir.exists(fig_dir)) dir.create(fig_dir, recursive = TRUE)

  all_results <- purrr::compact(all_results)
  if (!length(all_results)) all_results <- list(active = resultado)

  summary <- make_summary_table(resultado)
  history <- make_history_table(resultado)
  history_all <- make_history_table_all_models(all_results)
  metrics <- compute_fit_metrics_all(all_results)
  projection_all <- purrr::map_dfr(all_results, "proyeccion")

  oos <- compute_pseudo_oos_metrics(eval_start_date = as.Date(eval_start_date), models = names(all_results)[names(all_results) %in% c("base", "ine")])

  readr::write_csv(summary, file.path(output_dir, "imacec_nowcast_summary.csv"))
  readr::write_csv(history, file.path(output_dir, "imacec_nowcast_history.csv"))
  readr::write_csv(history_all, file.path(output_dir, "imacec_nowcast_history_all_models.csv"))
  readr::write_csv(metrics, file.path(output_dir, "imacec_model_metrics.csv"))
  readr::write_csv(resultado$proyeccion, file.path(output_dir, "imacec_projection.csv"))
  readr::write_csv(projection_all, file.path(output_dir, "imacec_projection_all_models.csv"))
  readr::write_csv(oos$predictions, file.path(output_dir, "imacec_pseudo_oos_predictions.csv"))
  readr::write_csv(oos$metrics, file.path(output_dir, "imacec_pseudo_oos_metrics.csv"))

  g_total <- plot_nowcast(resultado, "total", ultimos_meses)
  g_nm <- plot_nowcast(resultado, "no_minero", ultimos_meses)

  ggplot2::ggsave(file.path(fig_dir, "imacec_total_nowcast.png"), g_total, width = 10, height = 6.2, dpi = 180)
  ggplot2::ggsave(file.path(fig_dir, "imacec_no_minero_nowcast.png"), g_nm, width = 10, height = 6.2, dpi = 180)

  invisible(list(
    summary = summary,
    history = history,
    history_all = history_all,
    metrics = metrics,
    projection = resultado$proyeccion,
    projection_all = projection_all,
    pseudo_oos_metrics = oos$metrics,
    pseudo_oos_predictions = oos$predictions,
    g_total = g_total,
    g_nm = g_nm
  ))
}
