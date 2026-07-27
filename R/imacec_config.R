# ============================================================
# imacec_config.R
# Parámetros y códigos de series para nowcasting IMACEC
# ============================================================

# Nunca escribas credenciales reales dentro de scripts versionados en GitHub.
# Define estas variables en tu archivo .Renviron local:
# BCCH_USER=tu_usuario
# BCCH_PASS=tu_password

USER_BCCH <- Sys.getenv("BCCH_USER")
PASS_BCCH <- Sys.getenv("BCCH_PASS")

first_date <- Sys.getenv("IMACEC_FIRST_DATE", unset = "2017-01-01")
last_date  <- Sys.getenv("IMACEC_LAST_DATE", unset = format(Sys.Date(), "%Y-%m-%d"))

# El archivo debe existir localmente para correr la actualización real.
# Déjalo en data/raw/cal_1985_2030.xlsx o cambia la ruta con variable de entorno.
cal_path <- Sys.getenv("IMACEC_CAL_PATH", unset = "data/raw/cal_1985_2030.xlsx")


# Página pública de la BDE con la EEE de PIB/IMACEC. Se usa solo para
# extraer el nowcast temprano de IMACEC/IMACEC no minero cuando aún no
# existen indicadores sectoriales INE del mes objetivo.
eee_imacec_url <- Sys.getenv(
  "IMACEC_EEE_URL",
  unset = "https://si3.bcentral.cl/Siete/ES/Siete/Cuadro/CAP_BDP/MN_EXP_EC11/EXE_BCCH_05/EXE_BCCH_05"
)

# Códigos BCCh / INE usados en la versión actual del prototipo.
# Validar periódicamente en la BDE si cambia la codificación o definición de una serie.
codes <- list(
  imacec_nm      = "F032.IMC.IND.Z.Z.EP18.N03.Z.0.M",
  imacec         = "F032.IMC.IND.Z.Z.EP18.Z.Z.0.M",
  ivdcm_yoy      = "F034.VDCM.TAS12M.DBC.2018.0.M",
  credito_monto  = "F034.ICCEM.FLU.Z.Z.D00T.M",
  credito_cant   = "F034.ICCEF.FLU.Z.Z.D00T.M",
  uf_daily       = "F073.UFF.PRE.Z.D",
  desempleo      = "F049.DES.TAS.INE9.10.M",
  cobre          = "F019.PPB.PRE.40.M",
  petroleo       = "F019.PPB.PRE.41AB.M"
)

codes_ine <- list(
  mineria      = "F034.PMI.IND.INE.2018.1.M",
  manufactura  = "F034.PRM.IND.INE.2018.1.M",
  comercio     = "F034.VCC.IND.INE.2018.1.M",
  electricidad = "F034.PEGA.IND.INE.2018.1.M",
  desempleo    = "F049.DES.TAS.INE9.10.M"
)
