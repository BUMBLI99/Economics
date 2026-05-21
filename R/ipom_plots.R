# ============================================================
# Gráficos y tablas para proyecto IPoM / IRIS
# ============================================================

ipom_plot_var <- function(
    data,
    variable_code,
    title = NULL,
    subtitle = NULL,
    ylab = NULL,
    start_period = "2018Q1",
    end_period = NULL,
    scenarios = NULL,
    baseline_id = "baseline_ipom",
    line_size = 0.50,
    baseline_color = "#E76F51",
    scenario_color = "#00BFC4",
    y_nticks = 8,
    x_nticks = 10
) {
  stopifnot(all(c("period", "date", "scenario_id", "scenario", "variable", "value") %in% names(data)))
  
  plot_data <- data |>
    dplyr::filter(.data$variable == variable_code, .data$period >= start_period)
  
  if (!is.null(end_period)) {
    plot_data <- plot_data |>
      dplyr::filter(.data$period <= end_period)
  }
  
  if (!is.null(scenarios)) {
    plot_data <- plot_data |>
      dplyr::filter(.data$scenario_id %in% scenarios)
  }
  
  if (nrow(plot_data) == 0) {
    stop(sprintf("No hay datos para la variable %s con esos filtros.", variable_code))
  }
  
  var_label <- plot_data$label[which(!is.na(plot_data$label))[1]]
  var_unit  <- plot_data$unit[which(!is.na(plot_data$unit))[1]]
  
  if (is.null(title)) title <- var_label
  if (is.null(ylab)) ylab <- var_unit
  
  baseline_data <- plot_data |>
    dplyr::filter(.data$scenario_id == baseline_id)
  
  scenario_data <- plot_data |>
    dplyr::filter(.data$scenario_id != baseline_id)
  
  # Orden de leyenda: baseline primero, luego escenarios
  scenario_levels <- c(
    unique(baseline_data$scenario),
    setdiff(unique(plot_data$scenario), unique(baseline_data$scenario))
  )
  
  baseline_data <- baseline_data |>
    dplyr::mutate(scenario = factor(.data$scenario, levels = scenario_levels))
  
  scenario_data <- scenario_data |>
    dplyr::mutate(scenario = factor(.data$scenario, levels = scenario_levels))
  
  color_values <- c()
  if (nrow(baseline_data) > 0) {
    color_values[as.character(unique(baseline_data$scenario)[1])] <- baseline_color
  }
  if (nrow(scenario_data) > 0) {
    scen_names <- unique(as.character(scenario_data$scenario))
    scen_cols <- rep(scenario_color, length(scen_names))
    names(scen_cols) <- scen_names
    color_values <- c(color_values, scen_cols)
  }
  
  g <- ggplot2::ggplot() +
    ggplot2::geom_hline(yintercept = 0, linewidth = 0.25, color = "grey75") +
    ggplot2::geom_line(
      data = scenario_data,
      ggplot2::aes(
        x = .data$date,
        y = .data$value,
        color = .data$scenario,
        group = .data$scenario,
        text = paste0(
          "<b>Escenario:</b> ", .data$scenario,
          "<br><b>Fecha:</b> ", .data$period,
          "<br><b>Valor:</b> ", round(.data$value, 3)
        )
      ),
      linewidth = line_size,
      na.rm = TRUE
    ) +
    ggplot2::geom_line(
      data = baseline_data,
      ggplot2::aes(
        x = .data$date,
        y = .data$value,
        color = .data$scenario,
        group = .data$scenario,
        text = paste0(
          "<b>Escenario:</b> ", .data$scenario,
          "<br><b>Fecha:</b> ", .data$period,
          "<br><b>Valor:</b> ", round(.data$value, 3)
        )
      ),
      linewidth = line_size,
      na.rm = TRUE
    ) +
    ggplot2::scale_color_manual(values = color_values, breaks = scenario_levels) +
    ggplot2::scale_y_continuous(n.breaks = y_nticks) +
    ggplot2::scale_x_date(
      date_breaks = "1 year",
      date_labels = "%Y",
      expand = ggplot2::expansion(mult = c(0.01, 0.02))
    ) +
    ggplot2::labs(
      title = title,
      subtitle = subtitle,
      x = NULL,
      y = ylab,
      color = NULL
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      legend.position = "bottom",
      legend.direction = "horizontal",
      legend.title = ggplot2::element_blank(),
      plot.title = ggplot2::element_text(face = "bold", margin = ggplot2::margin(b = 6)),
      plot.subtitle = ggplot2::element_text(color = "grey35"),
      panel.grid.minor = ggplot2::element_blank()
    )
  
  plotly::ggplotly(g, tooltip = "text", dynamicTicks = TRUE) |>
    plotly::layout(
      hovermode = "x unified",
      legend = list(
        orientation = "h",
        x = 0.5,
        xanchor = "center",
        y = -0.22,
        yanchor = "top"
      ),
      xaxis = list(
        automargin = TRUE,
        nticks = x_nticks,
        tickangle = 0
      ),
      yaxis = list(
        automargin = TRUE,
        nticks = y_nticks,
        tickformat = ".1f"
      ),
      margin = list(t = 80, b = 95)
    )
}

ipom_plot_diff <- function(
    differences,
    variable_code,
    title = NULL,
    ylab = "Diferencia respecto del escenario base",
    start_period = "2025Q1",
    end_period = NULL,
    scenarios = NULL,
    line_size = 0.50,
    scenario_color = "#00BFC4",
    y_nticks = 8,
    x_nticks = 10
) {
  stopifnot(all(c("period", "date", "scenario_id", "scenario", "variable", "difference_vs_baseline") %in% names(differences)))
  
  plot_data <- differences |>
    dplyr::filter(.data$variable == variable_code, .data$period >= start_period)
  
  if (!is.null(end_period)) {
    plot_data <- plot_data |>
      dplyr::filter(.data$period <= end_period)
  }
  
  if (!is.null(scenarios)) {
    plot_data <- plot_data |>
      dplyr::filter(.data$scenario_id %in% scenarios)
  }
  
  if (nrow(plot_data) == 0) {
    stop(sprintf("No hay diferencias para la variable %s con esos filtros.", variable_code))
  }
  
  var_label <- plot_data$label[which(!is.na(plot_data$label))[1]]
  if (is.null(title)) title <- paste0(var_label, ": desvío frente al escenario base")
  
  color_values <- rep(scenario_color, length(unique(plot_data$scenario)))
  names(color_values) <- unique(plot_data$scenario)
  
  g <- ggplot2::ggplot(
    plot_data,
    ggplot2::aes(
      x = .data$date,
      y = .data$difference_vs_baseline,
      color = .data$scenario,
      group = .data$scenario,
      text = paste0(
        "<b>Escenario:</b> ", .data$scenario,
        "<br><b>Fecha:</b> ", .data$period,
        "<br><b>Diferencia:</b> ", round(.data$difference_vs_baseline, 3)
      )
    )
  ) +
    ggplot2::geom_hline(yintercept = 0, linewidth = 0.25, color = "grey60") +
    ggplot2::geom_line(linewidth = line_size, na.rm = TRUE) +
    ggplot2::scale_color_manual(values = color_values) +
    ggplot2::scale_y_continuous(n.breaks = y_nticks) +
    ggplot2::scale_x_date(
      date_breaks = "1 year",
      date_labels = "%Y",
      expand = ggplot2::expansion(mult = c(0.01, 0.02))
    ) +
    ggplot2::labs(title = title, x = NULL, y = ylab, color = NULL) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      legend.position = "bottom",
      legend.direction = "horizontal",
      panel.grid.minor = ggplot2::element_blank(),
      plot.title = ggplot2::element_text(face = "bold", margin = ggplot2::margin(b = 8))
    )
  
  plotly::ggplotly(g, tooltip = "text", dynamicTicks = TRUE) |>
    plotly::layout(
      hovermode = "x unified",
      legend = list(
        orientation = "h",
        x = 0.5,
        xanchor = "center",
        y = -0.22,
        yanchor = "top"
      ),
      xaxis = list(
        automargin = TRUE,
        nticks = x_nticks,
        tickangle = 0
      ),
      yaxis = list(
        automargin = TRUE,
        nticks = y_nticks,
        tickformat = ".2f"
      ),
      margin = list(t = 80, b = 95)
    )
}

ipom_kable <- function(data, caption = NULL, digits = 2) {
  knitr::kable(
    data,
    digits = digits,
    caption = caption,
    format.args = list(big.mark = ".", decimal.mark = ",")
  )
}

ipom_latest_values <- function(data, period = NULL, variables = c("D4L_CPI", "D4L_CPIXFE", "TPM", "L_GDP_GAP")) {
  if (is.null(period)) {
    period <- data |>
      dplyr::filter(.data$scenario_id == "baseline_ipom", .data$variable %in% variables, !is.na(.data$value)) |>
      dplyr::summarise(period = max(.data$period, na.rm = TRUE)) |>
      dplyr::pull(period)
  }
  
  data |>
    dplyr::filter(.data$period == period, .data$variable %in% variables) |>
    dplyr::select(Escenario = .data$scenario, Variable = .data$label, Valor = .data$value, Unidad = .data$unit) |>
    dplyr::arrange(.data$Variable, .data$Escenario)
}