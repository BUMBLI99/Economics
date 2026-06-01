# ============================================================
# 01_update_imacec.R
# Actualiza datos, estima modelos y exporta resultados del proyecto IMACEC
# ============================================================
# Uso desde la raíz del repositorio Economics:
#   Rscript scripts/01_update_imacec.R
#
# Requisitos locales:
#   1) .Renviron con BCCH_USER y BCCH_PASS
#   2) data/raw/cal_1985_2030.xlsx
# ============================================================

source("R/imacec_run_all.R", encoding = "UTF-8")

message("Iniciando actualización IMACEC...")
message("Rango de descarga: ", first_date, " a ", last_date)
message("Modelo: selección automática por vintage de información")

resultado <- run_nowcast(model = "auto")
exports <- export_imacec_outputs(
  resultado,
  output_dir = "data/processed",
  fig_dir = "assets/img/imacec",
  ultimos_meses = 96
)

message("Actualización finalizada.")
message("Última observación IMACEC: ", format(resultado$update_status$ultima_observacion_imacec, "%Y-%m"))
message("Período objetivo: ", format(resultado$proyeccion$Periodo, "%Y-%m"))
message("Vintage: ", resultado$proyeccion$vintage_label)
message("Nowcast IMACEC total: ", round(resultado$proyeccion$imacec_predicho, 2), "%")
message("Nowcast IMACEC no minero: ", round(resultado$proyeccion$imacec_nm_predicho, 2), "%")
if (!is.na(resultado$proyeccion$eee_imacec)) {
  message("EEE IMACEC total: ", round(resultado$proyeccion$eee_imacec, 2), "%")
}
message("Archivos exportados en data/processed y assets/img/imacec.")
message("Incluye archivo de vintage en data/processed/imacec_projection_archive.csv.")
