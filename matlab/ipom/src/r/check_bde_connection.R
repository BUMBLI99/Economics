# CHECK_BDE_CONNECTION
# Uso desde la raíz del proyecto:
#   source("src/r/check_bde_connection.R")

root <- normalizePath(getwd(), mustWork = TRUE)
local_renviron <- file.path(root, ".Renviron")
if (file.exists(local_renviron)) readRenviron(local_renviron)

missing <- c(
  if (identical(Sys.getenv("BDE_USER"), "")) "BDE_USER",
  if (identical(Sys.getenv("BDE_PASS"), "")) "BDE_PASS"
)
if (length(missing) > 0) stop("Faltan variables: ", paste(missing, collapse = ", "))

base_url <- "https://si3.bcentral.cl/SieteRestWS/SieteRestWS.ashx"
res <- httr::GET(
  base_url,
  query = list(
    user       = Sys.getenv("BDE_USER"),
    pass       = Sys.getenv("BDE_PASS"),
    timeseries = "F022.TPM.TIN.D001.NO.Z.M",
    firstdate  = "2026-01-01",
    lastdate   = format(Sys.Date(), "%Y-%m-%d"),
    `function` = "GetSeries"
  ),
  httr::timeout(60)
)

cat("HTTP status:", httr::status_code(res), "\n")
raw_txt <- httr::content(res, as = "raw")
txt <- rawToChar(raw_txt)
txt_utf8 <- iconv(txt, from = "UTF-8", to = "UTF-8", sub = "")
if (is.na(txt_utf8) || !nzchar(txt_utf8)) txt_utf8 <- iconv(txt, from = "latin1", to = "UTF-8", sub = "")
cat(substr(trimws(txt_utf8), 1, 500), "\n")

if (substr(trimws(txt_utf8), 1, 1) %in% c("{", "[")) {
  js <- jsonlite::fromJSON(txt_utf8, simplifyVector = FALSE)
  cat("Obs:", length(js$Series$Obs), "\n")
  cat("BDE OK\n")
} else {
  stop("BDE respondió algo que no parece JSON. Revisa credenciales o disponibilidad del servicio.")
}
