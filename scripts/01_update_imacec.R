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
message("Modelo: indicadores sectoriales INE")

resultado <- run_nowcast(model = "ine")
exports <- export_imacec_outputs(
  resultado,
  output_dir = "data/processed",
  fig_dir = "assets/img/imacec",
  ultimos_meses = 96
)

message("Actualización finalizada.")
message("Nowcast IMACEC total: ", round(resultado$proyeccion$imacec_predicho, 2), "%")
message("Nowcast IMACEC no minero: ", round(resultado$proyeccion$imacec_nm_predicho, 2), "%")
message("Archivos exportados en data/processed y assets/img/imacec.")
message("Incluye métricas pseudo out-of-sample en data/processed/imacec_oos_metrics.csv.")
