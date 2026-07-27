# ============================================================
# Utilidades para outputs IRIS / Matlab
# ============================================================

find_project_root <- function(path = getwd()) {
  path <- normalizePath(path, winslash = "/", mustWork = TRUE)
  for (i in seq_len(12)) {
    if (file.exists(file.path(path, "README.md")) &&
        dir.exists(file.path(path, "site")) &&
        dir.exists(file.path(path, "data"))) return(path)
    parent <- dirname(path)
    if (identical(parent, path)) break
    path <- parent
  }
  stop("No pude encontrar la raíz del repositorio Economics.", call. = FALSE)
}

path_project <- function(...) {
  file.path(find_project_root(), ...)
}

quarter_to_date <- function(x) {
  x <- as.character(x)
  y <- suppressWarnings(as.integer(sub("Q[1-4]$", "", x)))
  q <- suppressWarnings(as.integer(sub("^\\d{4}Q", "", x)))
  month <- (q - 1L) * 3L + 1L
  as.Date(sprintf("%04d-%02d-01", y, month))
}

read_iris_csv <- function(path) {
  if (!file.exists(path)) {
    stop("No existe el archivo IRIS: ", path, call. = FALSE)
  }

  out <- readr::read_csv(
    path,
    skip = 0,
    show_col_types = FALSE,
    na = c("", "NA", "NaN", "nan")
  )

  # dbsave de IRIS suele guardar tres filas de metadata:
  # Variables, Comments y Class[Size]. La primera ya quedó como encabezado.
  # Por eso se eliminan las filas 1 y 2 después de la lectura.
  if (nrow(out) >= 2 && grepl("Comments|Class", as.character(out[[1]][1]))) {
    out <- out[-c(1, 2), , drop = FALSE]
  } else if (nrow(out) >= 2 && grepl("Comments", paste(out[1, ], collapse = " "))) {
    out <- out[-c(1, 2), , drop = FALSE]
  }

  names(out)[1] <- "period"

  out <- out |>
    dplyr::mutate(
      period = as.character(.data$period),
      date = quarter_to_date(.data$period),
      .before = 2
    )

  numeric_cols <- setdiff(names(out), c("period", "date"))
  out[numeric_cols] <- lapply(out[numeric_cols], function(z) suppressWarnings(as.numeric(z)))

  out
}

add_ipom_derived_variables <- function(df) {
  if (!"D4L_CPI_GAP_XFE" %in% names(df) && all(c("D4L_CPI", "D4L_CPIXFE") %in% names(df))) {
    df$D4L_CPI_GAP_XFE <- df$D4L_CPI - df$D4L_CPIXFE
  }

  if (!"L_Z_INDEX" %in% names(df) && "L_Z" %in% names(df)) {
    df$L_Z_INDEX <- exp(df$L_Z / 100)
  }

  df
}

build_ipom_processed_data <- function(
    outputs_dir = path_project("matlab", "ipom", "output", "raw"),
    processed_dir = path_project("data", "processed", "ipom"),
    forecast_start_year = 2025,
    forecast_end_year = 2027
) {
  dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)

  scenarios <- ipom_scenarios
  variables <- ipom_variables

  wide_list <- list()

  for (i in seq_len(nrow(scenarios))) {
    source_file <- scenarios$source_file[i]
    source_path <- file.path(outputs_dir, source_file)

    if (!file.exists(source_path)) {
      warning("No encontré ", source_path, ". Se omite este escenario.")
      next
    }

    df <- read_iris_csv(source_path) |>
      add_ipom_derived_variables()

    keep <- intersect(variables$variable, names(df))

    df <- df |>
      dplyr::select(period, date, dplyr::all_of(keep)) |>
      dplyr::mutate(
        scenario_id = scenarios$scenario_id[i],
        scenario = scenarios$scenario[i],
        scenario_order = scenarios$scenario_order[i],
        .after = date
      )

    wide_list[[length(wide_list) + 1L]] <- df
  }

  if (length(wide_list) == 0L) {
    stop("No se pudo construir la base IPoM: no hay outputs IRIS disponibles.", call. = FALSE)
  }

  wide <- dplyr::bind_rows(wide_list) |>
    dplyr::arrange(.data$scenario_order, .data$date)

  long <- wide |>
    tidyr::pivot_longer(
      cols = -c(period, date, scenario_id, scenario, scenario_order),
      names_to = "variable",
      values_to = "value"
    ) |>
    dplyr::left_join(variables, by = "variable") |>
    dplyr::arrange(.data$scenario_order, .data$variable, .data$date)

  baseline <- long |>
    dplyr::filter(.data$scenario_id == "baseline_ipom") |>
    dplyr::select(period, date, variable, baseline_value = value)

  differences <- long |>
    dplyr::left_join(baseline, by = c("period", "date", "variable")) |>
    dplyr::filter(.data$scenario_id != "baseline_ipom") |>
    dplyr::mutate(difference_vs_baseline = .data$value - .data$baseline_value)

  diff_summary <- differences |>
    dplyr::filter(
      as.integer(substr(.data$period, 1, 4)) >= forecast_start_year,
      as.integer(substr(.data$period, 1, 4)) <= forecast_end_year,
      .data$variable %in% ipom_core_variables
    ) |>
    dplyr::group_by(.data$scenario_id, .data$scenario, .data$variable, .data$label, .data$unit) |>
    dplyr::summarise(
      promedio = mean(.data$difference_vs_baseline, na.rm = TRUE),
      minimo = min(.data$difference_vs_baseline, na.rm = TRUE),
      maximo = max(.data$difference_vs_baseline, na.rm = TRUE),
      ultimo = dplyr::last(.data$difference_vs_baseline),
      .groups = "drop"
    )

  external <- long |>
    dplyr::filter(
      .data$variable %in% ipom_external_variables,
      as.integer(substr(.data$period, 1, 4)) >= forecast_start_year,
      as.integer(substr(.data$period, 1, 4)) <= forecast_end_year
    ) |>
    dplyr::left_join(
      long |>
        dplyr::filter(.data$scenario_id == "baseline_ipom", .data$variable %in% ipom_external_variables) |>
        dplyr::select(period, variable, baseline_value = value),
      by = c("period", "variable")
    ) |>
    dplyr::mutate(difference_vs_baseline = .data$value - .data$baseline_value)

  readr::write_csv(long, file.path(processed_dir, "ipom_scenarios_long.csv"))
  readr::write_csv(wide, file.path(processed_dir, "ipom_scenarios_wide.csv"))
  readr::write_csv(variables, file.path(processed_dir, "ipom_variable_metadata.csv"))
  readr::write_csv(scenarios, file.path(processed_dir, "ipom_scenario_metadata.csv"))
  readr::write_csv(differences, file.path(processed_dir, "ipom_scenario_differences_long.csv"))
  readr::write_csv(diff_summary, file.path(processed_dir, "ipom_scenario_differences_summary.csv"))
  readr::write_csv(external, file.path(processed_dir, "ipom_external_assumptions.csv"))

  invisible(list(
    long = long,
    wide = wide,
    differences = differences,
    diff_summary = diff_summary,
    external = external
  ))
}
