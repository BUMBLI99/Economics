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

# Para evitar mezclar outputs viejos y nuevos, se limpian los archivos
# derivados antes de generar la nueva corrida. El archivo de archivo histórico
# de vintages NO se borra, porque acumula proyecciones anteriores.
processed_dir <- "data/processed"
fig_dir <- "assets/img/imacec"

derived_files <- file.path(processed_dir, c(
  "imacec_nowcast_history.csv",
  "imacec_nowcast_summary.csv",
  "imacec_model_metrics.csv",
  "imacec_oos_metrics.csv",
  "imacec_projection.csv",
  "imacec_update_status.csv",
  "imacec_assumptions.csv",
  "imacec_projection_evaluation.csv"
))

derived_figures <- file.path(fig_dir, c(
  "imacec_total_nowcast.png",
  "imacec_no_minero_nowcast.png"
))

unlink(c(derived_files, derived_figures), force = TRUE)

resultado <- run_nowcast(model = "auto")

exports <- export_imacec_outputs(
  resultado,
  output_dir = processed_dir,
  fig_dir = fig_dir,
  ultimos_meses = 96
)

validate_imacec_exports(resultado, output_dir = processed_dir)

message("Actualización finalizada.")
message("Última observación IMACEC: ", format(resultado$update_status$ultima_observacion_imacec, "%Y-%m"))
message("Período en pantalla: ", format(resultado$proyeccion$Periodo, "%Y-%m"))
message("Estado del ciclo: ", resultado$proyeccion$ciclo_estado_label)
message("Vintage/modelo: ", resultado$proyeccion$vintage_label)
message("Estimación IMACEC total: ", round(resultado$proyeccion$imacec_predicho, 2), "%")
message("Estimación IMACEC no minero: ", round(resultado$proyeccion$imacec_nm_predicho, 2), "%")
if (!is.na(resultado$proyeccion$eee_imacec)) {
  message("EEE IMACEC total: ", round(resultado$proyeccion$eee_imacec, 2), "%")
}
message("Archivos exportados y validados en data/processed y assets/img/imacec.")
message("Incluye archivo de vintage en data/processed/imacec_projection_archive.csv.")
