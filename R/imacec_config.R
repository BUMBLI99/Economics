# ============================================================
# imacec_config.R
# Parámetros y fuentes del nowcast IMACEC
# ============================================================

# Las credenciales nunca deben tener valores por defecto en código versionado.
# En local se leen desde .Renviron; en GitHub Actions, desde Repository Secrets.
USER_BCCH <- Sys.getenv("BCCH_USER")
PASS_BCCH <- Sys.getenv("BCCH_PASS")

first_date <- Sys.getenv("IMACEC_FIRST_DATE", unset = "2017-01-01")
last_date  <- Sys.getenv("IMACEC_LAST_DATE", unset = format(Sys.Date(), "%Y-%m-%d"))
cal_path   <- Sys.getenv("IMACEC_CAL_PATH", unset = "data/raw/cal_1985_2030.xlsx")
ivs_path   <- Sys.getenv(
  "IMACEC_IVS_FILE",
  unset = "data/raw/series_mensuales_desde_enero_2018_a_la_fecha.xls"
)
official_ivs_url <- paste0(
  "https://www.ine.gob.cl/docs/default-source/ventas-de-servicios/",
  "cuadro-estadisticos/base-promedio-a%C3%B1o-2018-100/",
  "series_mensuales_desde_enero_2018_a_la_fecha.xls?sfvrsn=1ff3a838_74"
)
ivs_url <- trimws(Sys.getenv("IMACEC_IVS_URL", unset = ""))
if (!nzchar(ivs_url)) ivs_url <- official_ivs_url
ivs_page <- paste0(
  "https://www.ine.gob.cl/estadisticas-por-tema/",
  "comercio-y-servicios/ventas-mensuales-de-servicios"
)

model_start_date <- as.Date(Sys.getenv("IMACEC_MODEL_START_DATE", unset = "2019-01-01"))
oos_start_date   <- as.Date(Sys.getenv("IMACEC_EVAL_START_DATE", unset = "2022-01-01"))
interval_level   <- as.numeric(Sys.getenv("IMACEC_INTERVAL_LEVEL", unset = "0.80"))
min_training_obs <- 48L
min_residual_df  <- 24L

codes <- list(
  imacec_total     = "F032.IMC.IND.Z.Z.EP18.Z.Z.0.M",
  imacec_no_minero = "F032.IMC.IND.Z.Z.EP18.N03.Z.0.M",
  venta_minorista  = "F034.VDCM.TAS12M.DBC.2018.0.M",
  credito_monto    = "F034.ICCEM.FLU.Z.Z.D00T.M",
  credito_cantidad = "F034.ICCEF.FLU.Z.Z.D00T.M",
  avisos_laborales = "F049.AVS.IND.BCC1.01.M",
  uf_diaria        = "F073.UFF.PRE.Z.D",
  ipc_servicios    = "F074.IPCS.IND.Z.EP23.Z.M",
  eee_imacec       = "F089.IMC.V12.10.M",
  eee_imacec_nm    = "F089.IMCNM.V12.10.M"
)

# M8P usa indicadores originales (sufijo 0.M), no desestacionalizados.
codes_ine <- list(
  mineria      = "F034.PMI.IND.INE.2018.0.M",
  manufactura  = "F034.PRM.IND.INE.2018.0.M",
  comercio     = "F034.VCC.IND.INE.2018.0.M",
  electricidad = "F034.PEGA.IND.INE.2018.0.M"
)

ivs_columns <- c(
  ivs_transporte_nivel = 3L,
  ivs_alojamiento_comidas_nivel = 7L,
  ivs_informacion_comunicaciones_nivel = 11L,
  ivs_inmobiliarias_nivel = 15L,
  ivs_profesionales_nivel = 19L,
  ivs_administrativos_apoyo_nivel = 23L
)
