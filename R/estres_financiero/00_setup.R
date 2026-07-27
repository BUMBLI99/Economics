# ============================================================
# 00_setup.R
# Proyecto: Índice de estrés financiero de mercado para Chile
# Objetivo: paquetes, rutas, configuración y utilidades generales.
# ============================================================

estres_required_packages <- c(
  "readr", "dplyr", "tidyr", "ggplot2", "zoo", "scales",
  "broom", "purrr", "stringr", "tibble", "rlang",
  "httr", "jsonlite", "lubridate"
)

estres_load_packages <- function(packages = estres_required_packages) {
  missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]

  if (length(missing) > 0) {
    stop(
      "Faltan paquetes requeridos: ", paste(missing, collapse = ", "),
      "\nInstala con: install.packages(c(",
      paste(sprintf('"%s"', missing), collapse = ", "), "))",
      call. = FALSE
    )
  }

  invisible(lapply(packages, function(pkg) {
    suppressPackageStartupMessages(library(pkg, character.only = TRUE))
  }))
}

estres_project_root <- function() {
  wd <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
  candidates <- unique(c(
    wd,
    normalizePath(file.path(wd, ".."), winslash = "/", mustWork = FALSE),
    normalizePath(file.path(wd, "../.."), winslash = "/", mustWork = FALSE)
  ))

  for (path in candidates) {
    if (file.exists(file.path(path, "README.md")) &&
        dir.exists(file.path(path, "site"))) return(path)
    if (file.exists(file.path(path, "R/estres_financiero/00_setup.R"))) return(path)
  }

  stop(
    "No pude identificar la raíz del proyecto. Ejecuta el script desde la carpeta del repositorio Economics.",
    call. = FALSE
  )
}

estres_path <- function(..., root = estres_project_root()) {
  file.path(root, ...)
}

estres_make_dirs <- function(root = estres_project_root()) {
  dirs <- c(
    "data/raw/estres_financiero",
    "data/processed/estres_financiero",
    "assets/img/estres_financiero",
    "outputs/tables/estres_financiero"
  )

  purrr::walk(file.path(root, dirs), dir.create, recursive = TRUE, showWarnings = FALSE)
  invisible(dirs)
}

estres_env_first <- function(...) {
  keys <- c(...)
  vals <- Sys.getenv(keys, unset = NA_character_)
  vals <- vals[!is.na(vals) & nzchar(trimws(vals))]
  if (length(vals) == 0) return(NA_character_)
  unname(trimws(vals[[1]]))
}

estres_parse_bool <- function(x, default = TRUE) {
  if (is.null(x) || length(x) == 0 || is.na(x) || !nzchar(x)) return(default)
  stringr::str_to_lower(as.character(x)) %in% c("true", "t", "1", "yes", "y", "si", "sí")
}

estres_api_config <- function() {
  list(
    bcch_user = estres_env_first("BCCH_USER", "BDE_USER", "BDE_EMAIL", "BCCH_EMAIL"),
    bcch_pass = estres_env_first("BCCH_PASS", "BDE_PASS", "BCCH_PASSWORD", "BDE_PASSWORD"),
    fred_api_key = estres_env_first("FRED_API_KEY", "FRED_KEY"),
    use_live = estres_parse_bool(Sys.getenv("ESTRES_USE_LIVE", unset = "TRUE"), default = TRUE),
    fallback_to_local = estres_parse_bool(Sys.getenv("ESTRES_FALLBACK_LOCAL", unset = "FALSE"), default = FALSE)
  )
}

estres_safe_log <- function(x) {
  x <- suppressWarnings(as.numeric(x))
  out <- rep(NA_real_, length(x))
  ok <- !is.na(x) & x > 0
  out[ok] <- log(x[ok])
  out
}

estres_zscore <- function(x) {
  mu <- mean(x, na.rm = TRUE)
  sig <- stats::sd(x, na.rm = TRUE)

  if (is.na(sig) || sig == 0) return(rep(NA_real_, length(x)))
  (x - mu) / sig
}

estres_interpolate_numeric <- function(x, date) {
  if (all(is.na(x))) return(x)

  zoo::na.approx(
    object = x,
    x = as.numeric(date),
    na.rm = FALSE
  )
}

estres_locf_then_interp <- function(x, date) {
  if (all(is.na(x))) return(x)
  out <- zoo::na.approx(x, x = as.numeric(date), na.rm = FALSE)
  out <- zoo::na.locf(out, na.rm = FALSE)
  out <- zoo::na.locf(out, fromLast = TRUE, na.rm = FALSE)
  out
}

estres_roll_mean <- function(x, width = 30, min_obs = 20) {
  zoo::rollapplyr(
    data = x,
    width = width,
    FUN = function(z) {
      if (sum(!is.na(z)) < min_obs) return(NA_real_)
      mean(z, na.rm = TRUE)
    },
    fill = NA_real_,
    partial = TRUE
  )
}

estres_theme <- function(base_size = 12) {
  ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(
      plot.title.position = "plot",
      plot.title = ggplot2::element_text(
        face = "bold", colour = "#1f2a35", size = base_size + 3,
        margin = ggplot2::margin(b = 6)
      ),
      plot.subtitle = ggplot2::element_text(
        colour = "#66717f", size = base_size,
        margin = ggplot2::margin(b = 10)
      ),
      axis.title = ggplot2::element_text(colour = "#66717f"),
      axis.text = ggplot2::element_text(colour = "#4d5662"),
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major.x = ggplot2::element_blank(),
      panel.grid.major.y = ggplot2::element_line(colour = "#e4dfd6", linewidth = 0.35),
      legend.position = "bottom",
      legend.direction = "horizontal",
      legend.title = ggplot2::element_blank(),
      legend.text = ggplot2::element_text(colour = "#4d5662"),
      legend.margin = ggplot2::margin(t = 6),
      legend.box.margin = ggplot2::margin(t = 4),
      plot.margin = ggplot2::margin(t = 14, r = 18, b = 12, l = 10),
      plot.background = ggplot2::element_rect(fill = "white", colour = NA),
      panel.background = ggplot2::element_rect(fill = "white", colour = NA)
    )
}
