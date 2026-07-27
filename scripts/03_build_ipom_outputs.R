# ============================================================
# Construye outputs limpios para la salidas públicas IPoM / IRIS
# ============================================================
# Ejecutar desde la raíz del repositorio:
# Rscript scripts/03_build_ipom_outputs.R

required <- c("dplyr", "tidyr", "readr", "tibble")
missing <- required[!vapply(required, requireNamespace, quietly = TRUE, FUN.VALUE = logical(1))]
if (length(missing) > 0) {
  stop("Faltan paquetes: ", paste(missing, collapse = ", "),
       ". Instálalos con install.packages().", call. = FALSE)
}

library(dplyr)
library(tidyr)
library(readr)
library(tibble)

source("R/ipom_config.R")
source("R/ipom_utils.R")

project_root <- find_project_root()

outputs_dir <- file.path(project_root, "matlab", "ipom", "output", "raw")
if (!dir.exists(outputs_dir)) {
  stop("No encontré matlab/ipom/output/raw. Ejecuta primero el pipeline Matlab/IRIS.", call. = FALSE)
}

message("Raíz del proyecto: ", project_root)
message("Leyendo outputs IRIS desde: ", outputs_dir)

out <- build_ipom_processed_data(
  outputs_dir = outputs_dir,
  processed_dir = file.path(project_root, "data", "processed", "ipom"),
  forecast_start_year = 2025,
  forecast_end_year = 2027
)

message("Listo. Archivos generados en data/processed/ipom/")
message("Filas long: ", nrow(out$long))
message("Filas wide: ", nrow(out$wide))
