# RUN_UPDATE_DATA_FROM_R
# Ejecuta el Rmd principal para actualizar data/raw/Data.csv.
# Uso recomendado desde la raíz del proyecto:
#   source("run_update_data_from_r.R")

root <- normalizePath(getwd(), mustWork = TRUE)
if (!file.exists(file.path(root, "config_ipom.m"))) {
  stop("Ejecuta este script desde la raíz del proyecto IPOM_IRIS_MATLAB.")
}

local_renviron <- file.path(root, ".Renviron")
if (file.exists(local_renviron)) {
  readRenviron(local_renviron)
}

missing <- c(
  if (identical(Sys.getenv("BDE_USER"), "")) "BDE_USER",
  if (identical(Sys.getenv("BDE_PASS"), "")) "BDE_PASS",
  if (identical(Sys.getenv("FRED_API_KEY"), "")) "FRED_API_KEY"
)

if (length(missing) > 0) {
  stop("Faltan variables en .Renviron o en el entorno: ", paste(missing, collapse = ", "))
}

if (!requireNamespace("rmarkdown", quietly = TRUE)) {
  stop("Falta el paquete rmarkdown. Instálalo con install.packages('rmarkdown').")
}

rmarkdown::render(
  input = file.path(root, "src", "r", "estimaciones_macro_ipom_tablas.Rmd"),
  output_dir = file.path(root, "output", "reports"),
  clean = TRUE
)

message("Listo. Revisa: ", file.path(root, "data", "raw", "Data.csv"))
