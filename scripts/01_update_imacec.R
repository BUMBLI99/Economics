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
#   3) Excel IVS oficial o IMACEC_IVS_URL para descargarlo
# ============================================================

source("R/imacec_run_all.R", encoding = "UTF-8")

message("Iniciando actualización IMACEC...")
message("Rango de descarga: ", first_date, " a ", last_date)
message("Evaluación pseudo-OOS desde: ", format(oos_start_date))
message("Construyendo base común y factor IVS real...")
data_imacec <- build_imacec_dataset()

message("Descargando y alineando EEE: encuesta M -> IMACEC M-1...")
eee <- get_eee_expectations()

message("Estimando únicamente M4 (experimental) y M8P (INE + IVS real)...")
resultados <- run_winner_models(data_imacec, eee)

if (!all(c("m4", "m8p") %in% names(resultados))) {
  stop("La actualización exige resultados válidos para ambos cortes: M4 y M8P.")
}

exports <- export_imacec_outputs(
  resultados,
  eee = eee,
  output_dir = "data/processed",
  fig_dir = "assets/img/imacec"
)

purrr::walk(resultados, function(result) {
  p <- result$proyeccion
  message(
    result$model_label, " · ", format(p$Periodo[1], "%Y-%m"), ": ",
    round(p$imacec_predicho[1], 2), "%",
    if (!is.na(p$eee_imacec[1])) paste0(" · EEE: ", round(p$eee_imacec[1], 2), "%") else " · EEE no disponible"
  )
})

message("Actualización finalizada: dos cortes, gráficos y comparación EEE exportados.")
