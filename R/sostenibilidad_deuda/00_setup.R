# Shared configuration for the Chile public-debt sustainability project.

debt_required_packages <- c(
  "dplyr", "tidyr", "purrr", "readr", "ggplot2", "scales"
)

debt_load_packages <- function() {
  missing <- debt_required_packages[
    !vapply(debt_required_packages, requireNamespace, logical(1), quietly = TRUE)
  ]
  if (length(missing)) {
    stop("Faltan paquetes: ", paste(missing, collapse = ", "),
         ". Ejecuta install.packages(debt_required_packages).")
  }
  invisible(lapply(debt_required_packages, library, character.only = TRUE))
}

debt_find_root <- function(start = getwd()) {
  path <- normalizePath(start, winslash = "/", mustWork = TRUE)
  repeat {
    if (file.exists(file.path(path, "data", "raw", "sostenibilidad_deuda",
                              "deuda_historica.csv"))) return(path)
    parent <- dirname(path)
    if (identical(parent, path)) stop("No se encontró la raíz del repositorio Economics.")
    path <- parent
  }
}

debt_path <- function(..., root = debt_find_root()) file.path(root, ...)
DEBT_PRUDENT_LEVEL <- 0.45
