# ============================================================
# 01_update_imacec.R
# Ejecuta el ciclo EEE -> M4 -> M8P -> dato efectivo
# ============================================================

source("R/imacec_run_all.R", encoding = "UTF-8")

message("Iniciando actualización mensual IMACEC...")
message("Rango de descarga: ", first_date, " a ", last_date)
message("Construyendo base común para IMACEC total y no minero...")
data_imacec <- build_imacec_dataset()

message("Descargando EEE y alineando encuesta M con IMACEC M-1...")
eee <- get_eee_expectations()

cycle <- build_cycle_state(data_imacec, eee)
message("Estado detectado: ", cycle$ciclo_estado_label[1])
message("Período objetivo: ", format(cycle$periodo_objetivo[1], "%Y-%m"))

results <- run_cycle_models(data_imacec, eee, cycle)
if (!length(results) && cycle$ciclo_estado[1] != "official_review") {
  stop("El ciclo activo no produjo una estimación publicable.")
}

exports <- export_imacec_outputs(
  results = results,
  data = data_imacec,
  eee = eee,
  cycle = cycle,
  output_dir = "data/processed",
  fig_dir = "assets/img/imacec"
)

if (nrow(exports$projections)) {
  purrr::pwalk(
    exports$projections[, c("variable", "modelo", "Periodo", "forecast", "eee_value")],
    function(variable, modelo, Periodo, forecast, eee_value) {
      message(
        variable, " · ", modelo, " · ", format(Periodo, "%Y-%m"), ": ",
        round(forecast, 2), "%",
        if (!is.na(eee_value)) paste0(" · EEE: ", round(eee_value, 2), "%") else " · EEE no disponible"
      )
    }
  )
}

message("Actualización finalizada. El vintage quedó archivado sin sobrescribir cortes anteriores.")
