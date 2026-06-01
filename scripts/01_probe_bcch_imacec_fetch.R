# Diagnóstico mínimo de descarga BCCh para IMACEC.
# Uso desde raíz del repo: Rscript scripts/01_probe_bcch_imacec_fetch.R
source("R/imacec_run_all.R", encoding = "UTF-8")

message("Probando lectura de serie IMACEC no minero: ", codes$imacec_nm)
x <- fetch_series(codes$imacec_nm)
message("OK. Observaciones recibidas: ", nrow(x))
if (nrow(x) > 0) {
  print(utils::tail(x, 5))
} else {
  warning("La serie se pudo leer, pero llegó sin observaciones.")
}

message("Probando lectura de serie IMACEC total: ", codes$imacec)
y <- fetch_series(codes$imacec)
message("OK. Observaciones recibidas: ", nrow(y))
if (nrow(y) > 0) {
  print(utils::tail(y, 5))
}
