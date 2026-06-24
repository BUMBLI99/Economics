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
#
# Parámetro opcional:
#   IMACEC_EVAL_START_DATE=2022-01-01
# ============================================================

source("R/imacec_run_all.R", encoding = "UTF-8")

message("Iniciando actualización IMACEC...")
message("Rango de descarga: ", first_date, " a ", last_date)
message("Evaluación pseudo-OOS desde: ", Sys.getenv("IMACEC_EVAL_START_DATE", unset = "2022-01-01"))

# Corre ambos modelos. El modelo INE queda como activo cuando está disponible,
# pero la página exporta ambos como benchmarks separados.
message("Estimando modelo con estadísticas experimentales...")
resultado_base <- run_nowcast_safe("base")

message("Estimando modelo con indicadores sectoriales INE...")
resultado_ine <- run_nowcast_safe("ine")

resultados <- list(base = resultado_base, ine = resultado_ine)
resultado_activo <- choose_active_nowcast(resultados)

message("Modelo activo publicado: ", resultado_activo$model_label)

exports <- export_imacec_outputs(
  resultado_activo,
  all_results = resultados,
  output_dir = "data/processed",
  fig_dir = "assets/img/imacec",
  ultimos_meses = 96,
  eval_start_date = as.Date(Sys.getenv("IMACEC_EVAL_START_DATE", unset = "2022-01-01"))
)

message("Actualización finalizada.")
message("Nowcast IMACEC total: ", round(resultado_activo$proyeccion$imacec_predicho, 2), "%")
message("Nowcast IMACEC no minero: ", round(resultado_activo$proyeccion$imacec_nm_predicho, 2), "%")
message("Archivos exportados en data/processed y assets/img/imacec.")
