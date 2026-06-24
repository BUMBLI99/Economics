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
message("Evaluación pseudo-OOS desde: ", Sys.getenv("IMACEC_EVAL_START_DATE", unset = "2021-01-01"))

message("Estimando modelo con estadísticas experimentales...")
resultado_base <- run_nowcast_safe("base")

message("Estimando modelo con indicadores sectoriales INE...")
resultado_ine <- run_nowcast_safe("ine")

message("Consultando EEE pública de PIB/IMACEC...")
eee_nowcast <- tryCatch(
  fetch_latest_eee_imacec(),
  error = function(e) {
    warning("No se pudo leer la EEE: ", conditionMessage(e), call. = FALSE)
    tibble::tibble()
  }
)

if (nrow(eee_nowcast) > 0) {
  message(
    "Última EEE detectada: encuesta ", format(eee_nowcast$survey_period[1], "%Y-%m"),
    ", mes objetivo ", format(eee_nowcast$Periodo[1], "%Y-%m"),
    ", IMACEC total = ", eee_nowcast$imacec_predicho[1],
    ", no minero = ", eee_nowcast$imacec_nm_predicho[1]
  )
} else {
  message("No se detectó EEE usable para IMACEC.")
}

resultados <- list(base = resultado_base, ine = resultado_ine)
resultado_activo <- choose_active_nowcast(resultados, eee_nowcast = eee_nowcast)

message("Modelo/fuente activa publicada: ", resultado_activo$model_label)
if (!is.null(resultado_activo$active_note)) message(resultado_activo$active_note)

exports <- export_imacec_outputs(
  resultado_activo,
  all_results = resultados,
  output_dir = "data/processed",
  fig_dir = "assets/img/imacec",
  ultimos_meses = 96,
  eval_start_date = as.Date(Sys.getenv("IMACEC_EVAL_START_DATE", unset = "2021-01-01"))
)

message("Actualización finalizada.")
message("Nowcast IMACEC total: ", round(resultado_activo$proyeccion$imacec_predicho, 2), "%")
message("Nowcast IMACEC no minero: ", round(resultado_activo$proyeccion$imacec_nm_predicho, 2), "%")
message("Archivos exportados en data/processed y assets/img/imacec.")
