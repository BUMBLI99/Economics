# ============================================================
# ExchangeReg: FX, tasas 10Y y riesgo soberano LatAm
# Objetivo: replicar el modelo FX/EMBI y generar outputs web
#           para Quarto/GitHub Pages.
# ============================================================

args <- commandArgs(trailingOnly = TRUE)
repo <- if (length(args) >= 1) args[[1]] else getwd()
repo <- normalizePath(repo, winslash = "/", mustWork = TRUE)
setwd(repo)

renv <- file.path(repo, ".Renviron")
if (file.exists(renv)) readRenviron(renv)

message("Repo: ", repo)

required <- c(
  "httr", "jsonlite", "dplyr", "tidyr", "tibble", "lubridate",
  "zoo", "purrr", "readr", "ggplot2", "scales", "openxlsx"
)
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing) > 0) {
  message("Instalando paquetes faltantes: ", paste(missing, collapse = ", "))
  install.packages(missing, repos = "https://cloud.r-project.org")
}

suppressPackageStartupMessages({
  library(httr)
  library(jsonlite)
  library(dplyr)
  library(tidyr)
  library(tibble)
  library(lubridate)
  library(zoo)
  library(purrr)
  library(readr)
  library(ggplot2)
  library(scales)
  library(openxlsx)
})

# ------------------------------------------------------------
# Parametros y credenciales
# ------------------------------------------------------------
bde_user     <- Sys.getenv("BCCH_USER")
bde_pass     <- Sys.getenv("BCCH_PASS")
fred_api_key <- Sys.getenv("FRED_API_KEY")

start_date <- Sys.getenv("EXCHANGE_START_DATE")
if (!nzchar(start_date)) start_date <- "2010-01-01"
end_date <- Sys.getenv("EXCHANGE_END_DATE")
if (!nzchar(end_date)) end_date <- format(Sys.Date(), "%Y-%m-%d")
from_export <- as.Date(Sys.getenv("EXCHANGE_EXPORT_FROM"))
if (is.na(from_export)) from_export <- as.Date("2025-01-01")

cpi_extension_window <- suppressWarnings(as.integer(Sys.getenv("EXCHANGE_CPI_EXTENSION_WINDOW")))
if (is.na(cpi_extension_window) || cpi_extension_window < 1L) cpi_extension_window <- 6L

needed_env <- c("BCCH_USER", "BCCH_PASS", "FRED_API_KEY")
missing_env <- needed_env[!nzchar(Sys.getenv(needed_env))]
if (length(missing_env) > 0) {
  stop(
    "Faltan variables en .Renviron o en el entorno: ",
    paste(missing_env, collapse = ", "),
    "\nCopia .Renviron.example como .Renviron y completa tus claves."
  )
}

countries <- c("CLP", "BRL", "MXN", "PEN", "COP")

out_data <- file.path(repo, "data", "processed", "exchange")
out_img  <- file.path(repo, "assets", "img", "exchange")
out_file <- file.path(repo, "assets", "files")
dir.create(out_data, recursive = TRUE, showWarnings = FALSE)
dir.create(out_img,  recursive = TRUE, showWarnings = FALSE)
dir.create(out_file, recursive = TRUE, showWarnings = FALSE)

# ------------------------------------------------------------
# Helpers de descarga y transformacion
# ------------------------------------------------------------
parse_num <- function(x) {
  suppressWarnings(as.numeric(gsub(",", ".", as.character(x), fixed = TRUE)))
}

bde_get_series <- function(user, pass, series_id,
                           first_date = "2010-01-01",
                           last_date  = format(Sys.Date(), "%Y-%m-%d")) {
  base_url <- "https://si3.bcentral.cl/SieteRestWS/SieteRestWS.ashx"
  res <- httr::GET(
    base_url,
    query = list(
      user       = user,
      pass       = pass,
      timeseries = series_id,
      firstdate  = first_date,
      lastdate   = last_date,
      `function` = "GetSeries"
    ),
    httr::timeout(60)
  )
  httr::stop_for_status(res)
  txt <- httr::content(res, as = "text", encoding = "UTF-8")
  txt <- iconv(txt, from = "UTF-8", to = "UTF-8", sub = "")
  if (is.na(txt) || !nzchar(txt)) {
    raw <- httr::content(res, as = "raw")
    txt <- iconv(rawToChar(raw), from = "latin1", to = "UTF-8", sub = "")
  }
  json_data <- jsonlite::fromJSON(txt, simplifyVector = FALSE)
  if (is.null(json_data$Series$Obs) || length(json_data$Series$Obs) == 0) {
    warning("Sin observaciones para la serie BCCh: ", series_id)
    return(tibble(date = as.Date(character()), value_num = numeric()))
  }
  obs_list <- json_data$Series$Obs
  df <- do.call(rbind, lapply(obs_list, function(x) {
    data.frame(
      date_str = enc2utf8(as.character(x$indexDateString)),
      value    = enc2utf8(as.character(x$value)),
      stringsAsFactors = FALSE
    )
  }))
  df %>%
    mutate(
      date = as.Date(date_str, format = "%d-%m-%Y"),
      value_num = parse_num(value)
    ) %>%
    select(date, value_num) %>%
    filter(!is.na(date)) %>%
    arrange(date)
}

safe_bde_get_series <- function(user, pass, series_id,
                                first_date = "2010-01-01",
                                last_date  = format(Sys.Date(), "%Y-%m-%d")) {
  tryCatch(
    bde_get_series(user, pass, series_id, first_date, last_date),
    error = function(e) {
      warning(sprintf("No se pudo descargar BDE %s: %s", series_id, e$message))
      tibble(date = as.Date(character()), value_num = numeric())
    }
  )
}

fred_get_series <- function(api_key, series_id,
                            start_date = "2010-01-01",
                            end_date   = format(Sys.Date(), "%Y-%m-%d")) {
  url <- "https://api.stlouisfed.org/fred/series/observations"
  res <- httr::GET(url, query = list(
    series_id = series_id,
    api_key = api_key,
    file_type = "json",
    observation_start = start_date,
    observation_end = end_date
  ), httr::timeout(60))
  httr::stop_for_status(res)
  json_data <- jsonlite::fromJSON(httr::content(res, as = "text", encoding = "UTF-8"))
  df <- json_data$observations
  if (is.null(df) || nrow(df) == 0) {
    warning("Sin observaciones FRED: ", series_id)
    return(tibble(date = as.Date(character()), value_num = numeric()))
  }
  df %>%
    mutate(date = as.Date(date), value_num = parse_num(value)) %>%
    select(date, value_num) %>%
    filter(!is.na(date)) %>%
    arrange(date)
}

bis_get_daily <- function(dataflow, series_key,
                          start = "2010-01-01",
                          end   = format(Sys.Date(), "%Y-%m-%d")) {
  base <- sprintf("https://stats.bis.org/api/v2/data/dataflow/BIS/%s/1.0", dataflow)
  url <- sprintf("%s/%s?startPeriod=%s&endPeriod=%s&format=csv", base, series_key, start, end)
  res <- httr::GET(url, httr::timeout(60))
  httr::stop_for_status(res)
  csv_txt <- httr::content(res, as = "text", encoding = "UTF-8")
  df <- read.csv(text = csv_txt, stringsAsFactors = FALSE, check.names = FALSE)
  obs_col <- intersect(c("OBS_VALUE", "ObsValue", "value", "VALUE"), names(df))[1]
  if (is.na(obs_col) || !"TIME_PERIOD" %in% names(df)) {
    stop("Respuesta BIS inesperada para ", dataflow, " / ", series_key)
  }
  df %>%
    transmute(
      date = as.Date(TIME_PERIOD),
      value_num = parse_num(.data[[obs_col]])
    ) %>%
    filter(!is.na(date), !is.na(value_num)) %>%
    distinct(date, .keep_all = TRUE) %>%
    arrange(date)
}

bis_get_long_cpi_monthly <- function(series_key,
                                     start = "2010-01-01",
                                     end   = format(Sys.Date(), "%Y-%m-%d")) {
  base <- "https://stats.bis.org/api/v2/data/dataflow/BIS/WS_LONG_CPI/1.0"
  start_m <- format(as.Date(start), "%Y-%m")
  end_m   <- format(as.Date(end),   "%Y-%m")
  url <- sprintf("%s/%s?startPeriod=%s&endPeriod=%s&format=csv", base, series_key, start_m, end_m)
  res <- httr::GET(url, httr::timeout(60))
  httr::stop_for_status(res)
  csv_txt <- httr::content(res, as = "text", encoding = "UTF-8")
  df <- read.csv(text = csv_txt, stringsAsFactors = FALSE, check.names = FALSE)
  obs_col <- intersect(c("OBS_VALUE", "ObsValue", "value", "VALUE"), names(df))[1]
  if (is.na(obs_col) || !"TIME_PERIOD" %in% names(df)) {
    stop("Respuesta BIS CPI inesperada para ", series_key)
  }
  df %>%
    transmute(
      date  = as.Date(paste0(substr(as.character(TIME_PERIOD), 1, 7), "-01")),
      value = parse_num(.data[[obs_col]])
    ) %>%
    filter(!is.na(date), !is.na(value), value > 0) %>%
    distinct(date, .keep_all = TRUE) %>%
    arrange(date)
}

extend_cpi_with_recent_average <- function(df_idx, end_date, window = 6L) {
  stopifnot(all(c("date", "value") %in% names(df_idx)))
  df_idx <- df_idx %>% arrange(date) %>% filter(!is.na(value), value > 0)
  if (nrow(df_idx) < 2) stop("Se necesitan al menos dos observaciones mensuales de CPI.")

  target_month <- lubridate::floor_date(as.Date(end_date), "month")
  last_obs <- max(df_idx$date, na.rm = TRUE)

  mom <- df_idx %>%
    arrange(date) %>%
    mutate(mom = value / dplyr::lag(value) - 1) %>%
    pull(mom) %>%
    stats::na.omit()

  assumption_mom <- mean(utils::tail(mom, window), na.rm = TRUE)
  if (!is.finite(assumption_mom)) assumption_mom <- 0

  if (last_obs >= target_month) {
    out <- df_idx %>% mutate(cpi_source = "observado")
    summary <- tibble(
      last_observed_month = last_obs,
      target_month = target_month,
      months_extended = 0L,
      assumed_monthly_inflation = assumption_mom,
      method = paste0("No extension; BIS CPI available through target month. Window=", window)
    )
    return(list(data = out, summary = summary))
  }

  extend_months <- seq(last_obs %m+% months(1), target_month, by = "month")
  last_value <- df_idx$value[which.max(df_idx$date)]
  assumed_values <- last_value * cumprod(rep(1 + assumption_mom, length(extend_months)))

  extension <- tibble(
    date = as.Date(extend_months),
    value = as.numeric(assumed_values),
    cpi_source = "supuesto_promedio_6m"
  )

  out <- bind_rows(
    df_idx %>% mutate(cpi_source = "observado"),
    extension
  ) %>% arrange(date)

  summary <- tibble(
    last_observed_month = last_obs,
    target_month = target_month,
    months_extended = length(extend_months),
    assumed_monthly_inflation = assumption_mom,
    method = paste0("Monthly CPI extended with average of last ", window, " observed m/m changes.")
  )

  list(data = out, summary = summary)
}

monthly_to_daily_log <- function(df_monthly, cal_dates) {
  stopifnot(all(c("date", "value") %in% names(df_monthly)))
  stopifnot("date" %in% names(cal_dates))
  df_monthly <- df_monthly %>% arrange(date) %>% filter(!is.na(value), value > 0)
  if (nrow(df_monthly) < 2) stop("Se necesitan al menos dos observaciones mensuales de CPI.")
  daily_full <- tibble(date = seq(min(df_monthly$date), max(cal_dates$date), by = "day")) %>%
    left_join(df_monthly %>% select(date, value), by = "date") %>%
    arrange(date) %>%
    mutate(log_val = if_else(!is.na(value) & value > 0, log(value), NA_real_))
  daily_full$log_val_interp <- zoo::na.approx(daily_full$log_val, x = daily_full$date, na.rm = FALSE)
  daily_full$log_val_interp <- zoo::na.locf(daily_full$log_val_interp, na.rm = FALSE)
  daily_full %>%
    mutate(value_daily = exp(log_val_interp)) %>%
    select(date, value_daily) %>%
    right_join(cal_dates, by = "date") %>%
    arrange(date)
}

parse_bcrp_date <- function(x) {
  x0 <- trimws(as.character(x))
  x0 <- iconv(x0, from = "", to = "ASCII//TRANSLIT", sub = "")
  out <- rep(as.Date(NA), length(x0))
  has_letters <- grepl("[A-Za-z]", x0)
  if (any(has_letters)) {
    xx <- x0[has_letters]
    xx <- gsub("\\.", "", xx)
    xx <- gsub("/", "", xx)
    xx <- gsub("-", "", xx)
    xx <- gsub("\\s+", "", xx)
    m <- regexec("^([0-9]{1,2})([A-Za-z]+)([0-9]{2}|[0-9]{4})$", xx)
    parts <- regmatches(xx, m)
    parsed <- rep(as.Date(NA), length(xx))
    month_map <- c(
      ene = 1, jan = 1, feb = 2, mar = 3, abr = 4, apr = 4,
      may = 5, jun = 6, jul = 7, ago = 8, aug = 8, set = 9,
      sep = 9, oct = 10, nov = 11, dic = 12, dec = 12
    )
    for (i in seq_along(parts)) {
      pp <- parts[[i]]
      if (length(pp) == 4) {
        dd <- suppressWarnings(as.integer(pp[2]))
        mm_key <- tolower(substr(pp[3], 1, 3))
        yy <- suppressWarnings(as.integer(pp[4]))
        if (!is.na(dd) && mm_key %in% names(month_map) && !is.na(yy)) {
          mm <- unname(month_map[[mm_key]])
          if (yy < 100) yy <- ifelse(yy >= 50, 1900 + yy, 2000 + yy)
          parsed[i] <- as.Date(sprintf("%04d-%02d-%02d", yy, mm, dd))
        }
      }
    }
    out[has_letters] <- parsed
  }
  no_letters <- !has_letters & nzchar(x0)
  if (any(no_letters)) {
    xx <- x0[no_letters]
    parsed <- suppressWarnings(lubridate::ymd(xx))
    idx <- is.na(parsed)
    if (any(idx)) parsed[idx] <- suppressWarnings(lubridate::dmy(xx[idx]))
    idx <- is.na(parsed)
    if (any(idx)) parsed[idx] <- suppressWarnings(lubridate::mdy(xx[idx]))
    out[no_letters] <- parsed
  }
  bad <- is.na(out) & nzchar(x0)
  if (any(bad)) {
    warning("No se pudieron parsear algunas fechas BCRP. Ejemplos: ", paste(utils::head(unique(x0[bad]), 5), collapse = ", "))
  }
  out
}

bcrp_get_one_series_json <- function(series_code, var_name,
                                     start = "1998-01-01",
                                     end   = format(Sys.Date(), "%Y-%m-%d")) {
  url <- sprintf(
    "https://estadisticas.bcrp.gob.pe/estadisticas/series/api/%s/json/%s/%s/esp",
    series_code, start, end
  )
  res <- httr::GET(url, httr::timeout(60))
  httr::stop_for_status(res)
  txt <- httr::content(res, as = "text", encoding = "UTF-8")
  js  <- jsonlite::fromJSON(txt, simplifyVector = FALSE)
  if (is.null(js$periods) || length(js$periods) == 0) {
    warning("BCRPData devolvio respuesta sin observaciones para: ", series_code)
    return(tibble(date = as.Date(character()), !!var_name := numeric()))
  }
  dates <- vapply(js$periods, `[[`, character(1), "name")
  values <- vapply(js$periods, function(p) {
    if (is.null(p$values) || length(p$values) == 0) NA_character_ else as.character(p$values[[1]])
  }, character(1))
  out <- tibble(
    date = parse_bcrp_date(dates),
    value = parse_num(values)
  ) %>%
    filter(!is.na(date)) %>%
    arrange(date) %>%
    rename(!!var_name := value)
  end_date_check <- as.Date(end)
  if (any(out$date > end_date_check, na.rm = TRUE)) {
    stop(
      "BCRPData produjo fechas posteriores al end solicitado para ", series_code,
      ". Ultima fecha parseada: ", max(out$date, na.rm = TRUE),
      ". Revisa parse_bcrp_date()."
    )
  }
  out
}

bcrp_get_many_series_safe <- function(code_map,
                                      start = "1998-01-01",
                                      end   = format(Sys.Date(), "%Y-%m-%d")) {
  series_list <- purrr::imap(code_map, ~ bcrp_get_one_series_json(.x, .y, start, end))
  purrr::reduce(series_list, full_join, by = "date") %>% arrange(date)
}

# Relleno de frecuencia diaria equivalente al script original:
# - series financieras: interpolación lineal de huecos internos;
# - series tipo TPM/EMBI: último dato observado hacia adelante.
# na.approx(..., na.rm = FALSE) no extrapola fuera del rango observado.
interp_daily <- function(x) {
  if (all(is.na(x))) return(x)
  zoo::na.approx(x, na.rm = FALSE)
}

locf_daily <- function(x) {
  if (all(is.na(x))) return(x)
  zoo::na.locf(x, na.rm = FALSE)
}

rmse <- function(x) sqrt(mean(x^2, na.rm = TRUE))

model_summary_row <- function(model, country, block, metadata = NULL) {
  tibble(
    country = country,
    block = block,
    n_obs = length(stats::resid(model)),
    r2 = unname(summary(model)$r.squared),
    adj_r2 = unname(summary(model)$adj.r.squared),
    rmse = rmse(stats::resid(model)),
    first_obs = if (!is.null(metadata)) as.character(metadata$first_obs[[1]]) else NA_character_,
    last_obs = if (!is.null(metadata)) as.character(metadata$last_obs[[1]]) else NA_character_
  )
}

# ------------------------------------------------------------
# Descarga de datos
# ------------------------------------------------------------
message("Descargando tasas soberanas 10Y desde BCCh...")
y10_clp <- bde_get_series(bde_user, bde_pass, "F022.BCLP.TIS.AN10.NO.Z.D", start_date, end_date) %>% rename(y10_clp = value_num)
y10_brl <- bde_get_series(bde_user, bde_pass, "F019.TBG.TAS.BRA.D",       start_date, end_date) %>% rename(y10_brl = value_num)
y10_mxn <- bde_get_series(bde_user, bde_pass, "F019.TBG.TAS.MEX.D",       start_date, end_date) %>% rename(y10_mxn = value_num)
y10_pen <- bde_get_series(bde_user, bde_pass, "F019.TBG.TAS.PER.D",       start_date, end_date) %>% rename(y10_pen = value_num)
y10_col <- bde_get_series(bde_user, bde_pass, "F019.TBG.TAS.COL.D",       start_date, end_date) %>% rename(y10_col = value_num)
y10_us  <- bde_get_series(bde_user, bde_pass, "F019.TBG.TAS.10.D",        start_date, end_date) %>% rename(y10_us = value_num)

message("Descargando TPM desde BCCh...")
tpm_clp <- safe_bde_get_series(bde_user, bde_pass, "F022.TPM.TIN.D001.NO.Z.D", start_date, end_date) %>% rename(tpm_clp = value_num)
tpm_brl <- safe_bde_get_series(bde_user, bde_pass, "F019.TPM.TIN.BRA.D",       start_date, end_date) %>% rename(tpm_brl = value_num)
tpm_mxn <- safe_bde_get_series(bde_user, bde_pass, "F019.TPM.TIN.MEX.D",       start_date, end_date) %>% rename(tpm_mxn = value_num)
tpm_pen <- safe_bde_get_series(bde_user, bde_pass, "F019.TPM.TIN.PER.D",       start_date, end_date) %>% rename(tpm_pen = value_num)
tpm_cop <- safe_bde_get_series(bde_user, bde_pass, "F019.TPM.TIN.COL.D",       start_date, end_date) %>% rename(tpm_cop = value_num)

message("Descargando commodities, equity y volatilidad...")
copper      <- bde_get_series(bde_user, bde_pass, "F019.PPB.PRE.100.D", start_date, end_date) %>% rename(copper = value_num)
eq_nsq      <- bde_get_series(bde_user, bde_pass, "F019.IBC.IND.51.D",  start_date, end_date) %>% rename(eq_nsq = value_num)
eq_cny      <- bde_get_series(bde_user, bde_pass, "F019.IBC.IND.CHN.D", start_date, end_date) %>% rename(eq_cny = value_num)
wti         <- fred_get_series(fred_api_key, "DCOILWTICO", start_date, end_date) %>% rename(wti = value_num)
vix         <- fred_get_series(fred_api_key, "VIXCLS",     start_date, end_date) %>% rename(vix = value_num)
gold_silver <- fred_get_series(fred_api_key, "NASDAQXAU", start_date, end_date) %>% rename(gold_silver = value_num)

message("Descargando BIS FX/EER/CPI...")
dtw <- bis_get_daily("WS_EER", "D.N.B.US", start_date, end_date) %>% rename(dtw = value_num)
fx_clp <- bis_get_daily("WS_XRU", "D.CL.CLP.A", start_date, end_date) %>% rename(fx_clp = value_num)
fx_brl <- bis_get_daily("WS_XRU", "D.BR.BRL.A", start_date, end_date) %>% rename(fx_brl = value_num)
fx_cny <- bis_get_daily("WS_XRU", "D.CN.CNY.A", start_date, end_date) %>% rename(cny_usd = value_num)
fx_mxn <- bis_get_daily("WS_XRU", "D.MX.MXN.A", start_date, end_date) %>% rename(fx_mxn = value_num)
fx_pen <- bis_get_daily("WS_XRU", "D.PE.PEN.A", start_date, end_date) %>% rename(fx_pen = value_num)
fx_cop <- bis_get_daily("WS_XRU", "D.CO.COP.A", start_date, end_date) %>% rename(fx_cop = value_num)

message("Descargando EMBIG diario desde BCRPData...")
embi_codes <- c(
  embi_latam = "PD04708XD",
  embi_pen   = "PD04709XD",
  embi_brl   = "PD04711XD",
  embi_mxn   = "PD04713XD",
  embi_cop   = "PD04715XD",
  embi_clp   = "PD38581XD",
  embi_em    = "PD38580XD"
)
embi <- bcrp_get_many_series_safe(embi_codes, start = start_date, end = end_date)

# ------------------------------------------------------------
# CPI diario y CPI relativo
# ------------------------------------------------------------
cpi_specs <- tribble(
  ~country, ~series_key,
  "CLP", "M.CL.628",
  "US",  "M.US.628",
  "BRL", "M.BR.628",
  "COP", "M.CO.628",
  "MXN", "M.MX.628",
  "PEN", "M.PE.628"
)

cpi_monthly_raw <- cpi_specs %>%
  mutate(data_raw = map(series_key, ~ bis_get_long_cpi_monthly(.x, start_date, end_date)))

cpi_extended <- cpi_monthly_raw %>%
  mutate(ext = map(data_raw, ~ extend_cpi_with_recent_average(.x, end_date, cpi_extension_window)))

cpi_monthly <- cpi_extended %>%
  transmute(country, series_key, data = map(ext, "data"))

cpi_extension_summary <- cpi_extended %>%
  transmute(country, series_key, summary = map(ext, "summary")) %>%
  tidyr::unnest(summary) %>%
  mutate(
    assumed_monthly_inflation_pct = 100 * assumed_monthly_inflation,
    cpi_extension_window = cpi_extension_window
  )

cal_trading <- fx_clp %>% select(date) %>% distinct() %>% arrange(date)

cpi_daily_wide <- cpi_monthly %>%
  mutate(daily = map(data, ~ monthly_to_daily_log(.x, cal_trading))) %>%
  select(country, daily) %>%
  tidyr::unnest(daily) %>%
  tidyr::pivot_wider(names_from = country, values_from = value_daily, names_prefix = "cpi_") %>%
  arrange(date)

cpi_sources <- cpi_extended %>%
  transmute(
    country,
    series_key,
    first_observed_date = map_chr(data_raw, ~ as.character(min(.x$date, na.rm = TRUE))),
    last_observed_date  = map_chr(data_raw, ~ as.character(max(.x$date, na.rm = TRUE))),
    n_observed_months   = map_int(data_raw, nrow),
    last_model_date = map_chr(map(ext, "data"), ~ as.character(max(.x$date, na.rm = TRUE)))
  )

readr::write_csv(cpi_sources, file.path(out_data, "cpi_sources.csv"))
readr::write_csv(cpi_extension_summary, file.path(out_data, "cpi_extension_summary.csv"))

# ------------------------------------------------------------
# Base diaria
# ------------------------------------------------------------
db_daily <- cal_trading %>%
  left_join(fx_clp,  by = "date") %>%
  left_join(fx_brl,  by = "date") %>%
  left_join(fx_mxn,  by = "date") %>%
  left_join(fx_pen,  by = "date") %>%
  left_join(fx_cop,  by = "date") %>%
  left_join(fx_cny,  by = "date") %>%
  left_join(y10_clp, by = "date") %>%
  left_join(y10_brl, by = "date") %>%
  left_join(y10_mxn, by = "date") %>%
  left_join(y10_pen, by = "date") %>%
  left_join(y10_col, by = "date") %>%
  left_join(y10_us,  by = "date") %>%
  left_join(tpm_clp, by = "date") %>%
  left_join(tpm_brl, by = "date") %>%
  left_join(tpm_mxn, by = "date") %>%
  left_join(tpm_pen, by = "date") %>%
  left_join(tpm_cop, by = "date") %>%
  left_join(eq_nsq,  by = "date") %>%
  left_join(eq_cny,  by = "date") %>%
  left_join(dtw,     by = "date") %>%
  left_join(vix,     by = "date") %>%
  left_join(wti,     by = "date") %>%
  left_join(copper,  by = "date") %>%
  left_join(gold_silver, by = "date") %>%
  left_join(embi,    by = "date") %>%
  left_join(cpi_daily_wide, by = "date") %>%
  arrange(date)

vars_daily_interp <- c(
  "fx_clp", "fx_brl", "fx_mxn", "fx_pen", "fx_cop", "cny_usd",
  "y10_clp", "y10_brl", "y10_mxn", "y10_pen", "y10_col", "y10_us",
  "wti", "copper", "eq_nsq", "eq_cny", "gold_silver", "dtw", "vix"
)

vars_daily_locf <- c(
  "tpm_clp", "tpm_brl", "tpm_mxn", "tpm_pen", "tpm_cop",
  "embi_latam", "embi_em", "embi_clp", "embi_brl", "embi_mxn", "embi_pen", "embi_cop"
)

# Agrega cualquier columna faltante de TPM/EMBI como NA para que el script falle solo si la especificacion la necesita.
for (nm in vars_daily_locf) {
  if (!nm %in% names(db_daily)) db_daily[[nm]] <- NA_real_
}

db_daily <- db_daily %>%
  arrange(date) %>%
  mutate(
    across(all_of(vars_daily_interp), interp_daily),
    across(all_of(vars_daily_locf), locf_daily)
  ) %>%
  mutate(
    trend = row_number(),
    log_cpi_rel_chl_us = log(cpi_CLP / cpi_US),
    log_cpi_rel_bra_us = log(cpi_BRL / cpi_US),
    log_cpi_rel_mex_us = log(cpi_MXN / cpi_US),
    log_cpi_rel_per_us = log(cpi_PEN / cpi_US),
    log_cpi_rel_col_us = log(cpi_COP / cpi_US),
    l_wti         = if_else(wti         > 0, log(wti),         NA_real_),
    l_pcu         = if_else(copper      > 0, log(copper),      NA_real_),
    l_gold_silver = if_else(gold_silver > 0, log(gold_silver), NA_real_),
    l_eqnsq       = if_else(eq_nsq      > 0, log(eq_nsq),      NA_real_),
    l_eqcny       = if_else(eq_cny      > 0, log(eq_cny),      NA_real_),
    l_vix         = if_else(vix         > 0, log(vix),         NA_real_),
    l_dtw         = if_else(dtw         > 0, log(dtw),         NA_real_),
    l_cny         = if_else(cny_usd     > 0, log(cny_usd),     NA_real_)
  )

# ------------------------------------------------------------
# Modelos FX y 10Y con EMBIG
# ------------------------------------------------------------
run_fx_model <- function(df, country_code, fx_var, cpi_rel_var) {
  df_model <- df %>%
    transmute(
      date,
      l_fx = if_else(.data[[fx_var]] > 0, log(.data[[fx_var]]), NA_real_),
      trend,
      cpi_rel = .data[[cpi_rel_var]],
      l_wti, l_pcu, l_gold_silver, l_eqnsq, l_eqcny, l_vix, l_dtw, l_cny, y10_us
    ) %>%
    drop_na()
  mod <- lm(
    l_fx ~ trend + cpi_rel + l_wti + l_pcu + l_gold_silver +
      l_eqnsq + l_eqcny + l_vix + l_dtw + l_cny + y10_us,
    data = df_model
  )
  df_model <- df_model %>%
    mutate(
      country = country_code,
      fitted_fx = fitted(mod),
      res_fx = resid(mod),
      z_res_fx = as.numeric((res_fx - mean(res_fx, na.rm = TRUE)) / sd(res_fx, na.rm = TRUE))
    )
  metadata <- tibble(model = "FX", country = country_code, first_obs = min(df_model$date), last_obs = max(df_model$date), n_obs = nrow(df_model))
  list(country = country_code, model = mod, metadata = metadata, residuals = df_model %>% select(date, country, l_fx, fitted_fx, res_fx, z_res_fx), data = df_model)
}

run_yield_model <- function(df, country_code, y10_var, embi_var, cpi_rel_var) {
  df_model <- df %>%
    transmute(
      date,
      y10 = .data[[y10_var]],
      y10_us = y10_us,
      embi = .data[[embi_var]],
      embi_100 = .data[[embi_var]] / 100,
      cpi_rel = .data[[cpi_rel_var]],
      trend,
      l_vix, l_eqnsq, l_dtw, l_cny
    ) %>%
    drop_na()
  mod <- lm(y10 ~ y10_us + embi_100 + l_vix + l_eqnsq + l_dtw + l_cny + trend, data = df_model)
  df_model <- df_model %>%
    mutate(
      country = country_code,
      fitted_y10 = fitted(mod),
      res_y10 = resid(mod),
      z_res_y10 = as.numeric((res_y10 - mean(res_y10, na.rm = TRUE)) / sd(res_y10, na.rm = TRUE))
    )
  metadata <- tibble(
    model = "10Y",
    country = country_code,
    first_obs = min(df_model$date),
    last_obs = max(df_model$date),
    n_obs = nrow(df_model),
    embi_min = min(df_model$embi, na.rm = TRUE),
    embi_max = max(df_model$embi, na.rm = TRUE),
    embi_sd = sd(df_model$embi, na.rm = TRUE)
  )
  list(country = country_code, model = mod, metadata = metadata, residuals = df_model %>% select(date, country, y10, fitted_y10, res_y10, z_res_y10), data = df_model)
}

fx_specs <- tribble(
  ~country, ~fx_var,   ~cpi_rel_var,
  "CLP",    "fx_clp",  "log_cpi_rel_chl_us",
  "BRL",    "fx_brl",  "log_cpi_rel_bra_us",
  "MXN",    "fx_mxn",  "log_cpi_rel_mex_us",
  "PEN",    "fx_pen",  "log_cpi_rel_per_us",
  "COP",    "fx_cop",  "log_cpi_rel_col_us"
)

yield_specs <- tribble(
  ~country, ~y10_var,  ~embi_var,  ~cpi_rel_var,
  "CLP",    "y10_clp", "embi_clp", "log_cpi_rel_chl_us",
  "BRL",    "y10_brl", "embi_brl", "log_cpi_rel_bra_us",
  "MXN",    "y10_mxn", "embi_mxn", "log_cpi_rel_mex_us",
  "PEN",    "y10_pen", "embi_pen", "log_cpi_rel_per_us",
  "COP",    "y10_col", "embi_cop", "log_cpi_rel_col_us"
)

message("Estimando modelos FX y 10Y/EMBIG...")
fx_results <- fx_specs %>% mutate(result = pmap(list(country, fx_var, cpi_rel_var), ~ run_fx_model(db_daily, ..1, ..2, ..3)))
yield_results <- yield_specs %>% mutate(result = pmap(list(country, y10_var, embi_var, cpi_rel_var), ~ run_yield_model(db_daily, ..1, ..2, ..3, ..4)))

fx_models <- setNames(lapply(fx_results$result, `[[`, "model"), fx_specs$country)
yield_models <- setNames(lapply(yield_results$result, `[[`, "model"), yield_specs$country)
fx_metadata <- map_dfr(fx_results$result, "metadata")
yield_metadata <- map_dfr(yield_results$result, "metadata")
model_sample_table <- bind_rows(fx_metadata, yield_metadata)

fx_model_data_all <- map_dfr(fx_results$result, "data")
yield_model_data_all <- map_dfr(yield_results$result, "data")
fx_residuals_all <- map_dfr(fx_results$result, "residuals")
yield_residuals_all <- map_dfr(yield_results$result, "residuals")

fx_residuals_wide <- fx_residuals_all %>% select(date, country, z_res_fx) %>% pivot_wider(names_from = country, values_from = z_res_fx, names_prefix = "z_res_fx_")
yield_residuals_wide <- yield_residuals_all %>% select(date, country, z_res_y10) %>% pivot_wider(names_from = country, values_from = z_res_y10, names_prefix = "z_res_y10_")

db_daily <- db_daily %>%
  select(-matches("^z_res_fx_"), -matches("^z_res_y10_")) %>%
  left_join(fx_residuals_wide, by = "date") %>%
  left_join(yield_residuals_wide, by = "date")

missing_fx_z <- setdiff(paste0("z_res_fx_", countries), names(db_daily))
missing_y10_z <- setdiff(paste0("z_res_y10_", countries), names(db_daily))
if (length(missing_fx_z) > 0) stop("Faltan columnas z_res_fx en db_daily: ", paste(missing_fx_z, collapse = ", "))
if (length(missing_y10_z) > 0) stop("Faltan columnas z_res_y10 en db_daily: ", paste(missing_y10_z, collapse = ", "))

fit_summary <- bind_rows(
  imap_dfr(fx_models, ~ model_summary_row(.x, .y, "FX", fx_metadata %>% filter(country == .y))),
  imap_dfr(yield_models, ~ model_summary_row(.x, .y, "10Y", yield_metadata %>% filter(country == .y)))
) %>% mutate(across(c(r2, adj_r2, rmse), ~ round(.x, 4)))

tidy_lm_coefficients <- function(model, country, block) {
  sm <- summary(model)$coefficients
  tibble(
    country = country,
    block = block,
    term = rownames(sm),
    estimate = unname(sm[, "Estimate"]),
    std_error = unname(sm[, "Std. Error"]),
    statistic = unname(sm[, "t value"]),
    p_value = unname(sm[, "Pr(>|t|)"])
  )
}

model_coefficients <- bind_rows(
  imap_dfr(fx_models, ~ tidy_lm_coefficients(.x, .y, "FX")),
  imap_dfr(yield_models, ~ tidy_lm_coefficients(.x, .y, "10Y"))
) %>% mutate(across(c(estimate, std_error, statistic, p_value), ~ signif(.x, 6)))

# ------------------------------------------------------------
# Segunda etapa: residuo FX vs spread 10Y
# ------------------------------------------------------------
run_second_stage_fx_y10 <- function(df, country_code, y10_var) {
  fx_col <- paste0("z_res_fx_", country_code)
  df_model <- df %>%
    transmute(
      date,
      z_fx = .data[[fx_col]],
      y10_spread = .data[[y10_var]] - y10_us
    ) %>%
    drop_na()
  mod <- lm(z_fx ~ y10_spread, data = df_model)
  df_model <- df_model %>% mutate(country = country_code, z_fx_hat = fitted(mod), res_2nd = resid(mod))
  list(country = country_code, model = mod, data = df_model)
}

second_stage_results <- yield_specs %>% mutate(result = map2(country, y10_var, ~ run_second_stage_fx_y10(db_daily, .x, .y)))
second_stage_models <- setNames(lapply(second_stage_results$result, `[[`, "model"), yield_specs$country)
second_stage_all <- map_dfr(second_stage_results$result, "data")

second_stage_summary <- imap_dfr(second_stage_models, function(mod, cc) {
  sm <- summary(mod)
  coefs <- sm$coefficients
  beta <- unname(coefs["y10_spread", "Estimate"])
  pval <- unname(coefs["y10_spread", "Pr(>|t|)"])
  tibble(
    country = cc,
    n_obs = length(resid(mod)),
    beta_y10_spread = beta,
    p_value = pval,
    r2 = unname(sm$r.squared),
    lectura = dplyr::case_when(
      is.na(pval) ~ "sin lectura",
      pval < 0.05 & beta > 0 ~ "relación positiva significativa",
      pval < 0.05 & beta < 0 ~ "relación negativa significativa",
      TRUE ~ "relación débil/no significativa"
    )
  )
}) %>% mutate(across(c(beta_y10_spread, p_value, r2), ~ round(.x, 4)))

# ------------------------------------------------------------
# Outputs para Quarto
# ------------------------------------------------------------
# Para los gráficos comparativos se usa la muestra común FX-10Y por país.
# Así los paneles regionales y los dashboards no muestran colas de un mercado
# que no tienen contraparte en el otro residuo del mismo país.
residuals_common_all <- fx_residuals_all %>%
  select(date, country, z_fx = z_res_fx, res_fx) %>%
  inner_join(
    yield_residuals_all %>%
      select(date, country, z_y10 = z_res_y10, res_y10),
    by = c("date", "country")
  ) %>%
  arrange(country, date)

residuals_long <- bind_rows(
  residuals_common_all %>% transmute(date, country, market = "FX",  z_score = z_fx,  residual = res_fx),
  residuals_common_all %>% transmute(date, country, market = "10Y", z_score = z_y10, residual = res_y10)
) %>% arrange(market, country, date)

latest_date <- max(residuals_long$date, na.rm = TRUE)
latest_snapshot <- residuals_long %>%
  filter(date == latest_date) %>%
  select(date, country, market, z_score) %>%
  pivot_wider(names_from = market, values_from = z_score) %>%
  arrange(country) %>%
  mutate(across(c(FX, `10Y`), ~ round(.x, 2)))

rates_embi_latest <- db_daily %>%
  filter(date == max(date, na.rm = TRUE)) %>%
  transmute(
    date,
    y10_clp, y10_brl, y10_mxn, y10_pen, y10_col, y10_us,
    embi_clp, embi_brl, embi_mxn, embi_pen, embi_cop,
    tpm_clp, tpm_brl, tpm_mxn, tpm_pen, tpm_cop
  )


country_dashboard_specs <- tibble::tribble(
  ~country, ~y10_var,  ~tpm_var,  ~country_name,
  "CLP",    "y10_clp", "tpm_clp", "Chile",
  "BRL",    "y10_brl", "tpm_brl", "Brasil",
  "MXN",    "y10_mxn", "tpm_mxn", "México",
  "PEN",    "y10_pen", "tpm_pen", "Perú",
  "COP",    "y10_col", "tpm_cop", "Colombia"
)

dashboard_country_data <- purrr::map_dfr(seq_len(nrow(country_dashboard_specs)), function(i) {
  spec <- country_dashboard_specs[i, ]
  cc <- spec$country
  y10_var <- spec$y10_var
  tpm_var <- spec$tpm_var
  fx_z_var <- paste0("z_res_fx_", cc)
  y10_z_var <- paste0("z_res_y10_", cc)

  # Se corta el dashboard en la última fecha donde existen desvíos del modelo.
  # Esto evita que tasas/TPM o variables financieras se proyecten visualmente
  # cuando alguna fuente diaria dejó de entregar datos recientes.
  last_model_cc <- db_daily %>%
    filter(!is.na(.data[[fx_z_var]]), !is.na(.data[[y10_z_var]])) %>%
    summarise(last_date = max(date, na.rm = TRUE)) %>%
    pull(last_date)

  if (!is.finite(as.numeric(last_model_cc))) {
    return(tibble(date = as.Date(character()), country = character(), panel = character(), series = character(), value = numeric()))
  }

  rates_panel <- db_daily %>%
    filter(date >= from_export, date <= last_model_cc) %>%
    transmute(
      date,
      country = cc,
      panel = "Tasas (%)",
      TPM = .data[[tpm_var]],
      `Tasa 10Y` = .data[[y10_var]]
    ) %>%
    pivot_longer(c(TPM, `Tasa 10Y`), names_to = "series", values_to = "value")

  z_panel <- db_daily %>%
    filter(date >= from_export, date <= last_model_cc) %>%
    transmute(
      date,
      country = cc,
      panel = "Desvíos del modelo (z-score)",
      FX = .data[[fx_z_var]],
      `Tasa 10Y` = .data[[y10_z_var]]
    ) %>%
    pivot_longer(c(FX, `Tasa 10Y`), names_to = "series", values_to = "value")

  bind_rows(rates_panel, z_panel)
}) %>%
  filter(!is.na(value)) %>%
  mutate(country = factor(country, levels = countries)) %>%
  arrange(country, panel, series, date)


readr::write_csv(db_daily, file.path(out_data, "db_daily_exchange.csv"))
readr::write_csv(residuals_long, file.path(out_data, "residuals_long.csv"))
readr::write_csv(fit_summary, file.path(out_data, "model_fit_summary.csv"))
readr::write_csv(model_coefficients, file.path(out_data, "model_coefficients.csv"))
readr::write_csv(second_stage_summary, file.path(out_data, "second_stage_summary.csv"))
readr::write_csv(second_stage_all, file.path(out_data, "second_stage_data.csv"))
readr::write_csv(latest_snapshot, file.path(out_data, "latest_snapshot.csv"))
readr::write_csv(model_sample_table, file.path(out_data, "model_sample_table.csv"))
readr::write_csv(rates_embi_latest, file.path(out_data, "rates_embi_latest.csv"))
readr::write_csv(dashboard_country_data, file.path(out_data, "country_dashboard_data.csv"))

metadata <- tibble(
  item = c("start_date", "end_date", "latest_model_date", "created_at", "model_version", "cpi_extension_window"),
  value = c(start_date, end_date, as.character(latest_date), as.character(Sys.time()), "FX_EMBI_CPI_BIS", as.character(cpi_extension_window))
)
readr::write_csv(metadata, file.path(out_data, "metadata.csv"))

# Excel opcional equivalente al script original, desde 2025.
z_scores_2025 <- db_daily %>% filter(date >= from_export) %>% select(date, starts_with("z_res_fx_"), starts_with("z_res_y10_"))
rates_2025 <- db_daily %>%
  filter(date >= from_export) %>%
  select(
    date,
    tpm_clp, tpm_brl, tpm_mxn, tpm_pen, tpm_cop,
    y10_clp, y10_brl, y10_mxn, y10_pen, y10_col, y10_us,
    embi_clp, embi_brl, embi_mxn, embi_pen, embi_cop,
    embi_latam, embi_em,
    log_cpi_rel_chl_us, log_cpi_rel_bra_us, log_cpi_rel_mex_us,
    log_cpi_rel_per_us, log_cpi_rel_col_us
  )
fx_model_data_2025 <- db_daily %>%
  filter(date >= from_export) %>%
  select(
    date,
    fx_clp, fx_brl, fx_mxn, fx_pen, fx_cop,
    y10_us, wti, copper, gold_silver, eq_nsq, eq_cny,
    vix, dtw, cny_usd, starts_with("log_cpi_rel_"), starts_with("z_res_fx_")
  )
latest_obs_table <- db_daily %>%
  summarise(across(-date, ~ {
    idx <- which(!is.na(.x))
    if (length(idx) == 0) as.Date(NA) else max(date[idx], na.rm = TRUE)
  })) %>%
  pivot_longer(everything(), names_to = "variable", values_to = "last_non_missing_obs") %>%
  arrange(variable)

# Datos exactos de gráficos para auditoría en Excel.
graph_normalized_fx <- residuals_common_all %>%
  filter(date >= as.Date("2022-01-01")) %>%
  transmute(date, country, serie = "FX", z_score = z_fx) %>%
  arrange(country, date)

graph_normalized_y10 <- residuals_common_all %>%
  filter(date >= as.Date("2022-01-01")) %>%
  transmute(date, country, serie = "Tasa 10Y", z_score = z_y10) %>%
  arrange(country, date)

graph_stress_fx_y10 <- residuals_common_all %>%
  select(date, country, FX = z_fx, `Tasa 10Y` = z_y10) %>%
  pivot_longer(c(FX, `Tasa 10Y`), names_to = "serie", values_to = "z_score") %>%
  arrange(country, serie, date)

graph_second_stage <- second_stage_all %>%
  transmute(date, country, y10_spread, z_fx, z_fx_hat, res_2nd) %>%
  arrange(country, date)

graph_dashboard <- purrr::map_dfr(seq_len(nrow(country_dashboard_specs)), function(i) {
  spec <- country_dashboard_specs[i, ]
  cc <- spec$country
  y10_var <- spec$y10_var
  tpm_var <- spec$tpm_var
  fx_z_var <- paste0("z_res_fx_", cc)
  y10_z_var <- paste0("z_res_y10_", cc)

  last_model_cc <- db_daily %>%
    filter(!is.na(.data[[fx_z_var]]), !is.na(.data[[y10_z_var]])) %>%
    summarise(last_date = max(date, na.rm = TRUE)) %>%
    pull(last_date)

  if (!is.finite(as.numeric(last_model_cc))) {
    return(tibble(date = as.Date(character()), country = character(), TPM = numeric(), Y10 = numeric(), FX_residual_z = numeric(), Y10_residual_z = numeric()))
  }

  db_daily %>%
    filter(date >= from_export, date <= last_model_cc) %>%
    transmute(
      date,
      country = cc,
      TPM = .data[[tpm_var]],
      Y10 = .data[[y10_var]],
      FX_residual_z = .data[[fx_z_var]],
      Y10_residual_z = .data[[y10_z_var]]
    )
}) %>% arrange(country, date)

model_fx_data_excel <- fx_model_data_all %>% arrange(country, date)
model_y10_data_excel <- yield_model_data_all %>% arrange(country, date)

graph_last_obs_summary <- bind_rows(
  graph_normalized_fx %>% group_by(country) %>% summarise(bloque = "Normalized FX residuals", first_obs = min(date, na.rm = TRUE), last_obs = max(date, na.rm = TRUE), n_obs = n(), .groups = "drop"),
  graph_normalized_y10 %>% group_by(country) %>% summarise(bloque = "Normalized 10Y residuals", first_obs = min(date, na.rm = TRUE), last_obs = max(date, na.rm = TRUE), n_obs = n(), .groups = "drop"),
  graph_stress_fx_y10 %>% group_by(country) %>% summarise(bloque = "Stress FX and 10Y", first_obs = min(date, na.rm = TRUE), last_obs = max(date, na.rm = TRUE), n_obs = n(), .groups = "drop"),
  graph_second_stage %>% group_by(country) %>% summarise(bloque = "Second stage FX vs 10Y spread", first_obs = min(date, na.rm = TRUE), last_obs = max(date, na.rm = TRUE), n_obs = n(), .groups = "drop"),
  graph_dashboard %>% group_by(country) %>% summarise(bloque = "Dashboard TPM 10Y zscores", first_obs = min(date, na.rm = TRUE), last_obs = max(date, na.rm = TRUE), n_obs = n(), .groups = "drop")
) %>% arrange(bloque, country)

wb <- openxlsx::createWorkbook()
write_sheet <- function(wb, sheet_name, data) {
  openxlsx::addWorksheet(wb, sheet_name)
  openxlsx::writeData(wb, sheet_name, data)
}

write_sheet(wb, "z_scores_2025", z_scores_2025)
write_sheet(wb, "rates_embi_2025", rates_2025)
write_sheet(wb, "fx_model_data_2025", fx_model_data_2025)
write_sheet(wb, "fx_model_data_used", fx_model_data_all)
write_sheet(wb, "yield_model_data_used", yield_model_data_all)
write_sheet(wb, "model_samples", model_sample_table)
write_sheet(wb, "latest_obs", latest_obs_table)
write_sheet(wb, "graph_normalized_fx", graph_normalized_fx)
write_sheet(wb, "graph_normalized_y10", graph_normalized_y10)
write_sheet(wb, "graph_stress_fx_y10", graph_stress_fx_y10)
write_sheet(wb, "graph_second_stage", graph_second_stage)
write_sheet(wb, "graph_dashboard", graph_dashboard)
write_sheet(wb, "model_fx_data", model_fx_data_excel)
write_sheet(wb, "model_y10_data", model_y10_data_excel)
write_sheet(wb, "graph_last_obs", graph_last_obs_summary)

openxlsx::saveWorkbook(wb, file = file.path(out_file, "exchange_model_outputs_2025.xlsx"), overwrite = TRUE)

# También se guardan CSV auxiliares de los gráficos para la página o revisión rápida.
readr::write_csv(graph_normalized_fx, file.path(out_data, "graph_normalized_fx.csv"))
readr::write_csv(graph_normalized_y10, file.path(out_data, "graph_normalized_y10.csv"))
readr::write_csv(graph_stress_fx_y10, file.path(out_data, "graph_stress_fx_y10.csv"))
readr::write_csv(graph_second_stage, file.path(out_data, "graph_second_stage.csv"))
readr::write_csv(graph_dashboard, file.path(out_data, "graph_dashboard.csv"))


# ------------------------------------------------------------
# Reporte PDF ligero para descarga web
# ------------------------------------------------------------
plot_static_residuals <- function(market_name, from_date = as.Date("2022-01-01")) {
  dfp <- residuals_long %>% filter(market == market_name, date >= from_date, !is.na(z_score))
  title <- if (market_name == "FX") "Residuos normalizados del tipo de cambio" else "Residuos normalizados de tasas soberanas 10Y"
  ggplot(dfp, aes(x = date, y = z_score, colour = country)) +
    geom_hline(yintercept = 0, linetype = "dashed", linewidth = 0.35, colour = "grey45") +
    geom_hline(yintercept = c(-2, 2), linetype = "dotted", linewidth = 0.3, colour = "grey60") +
    geom_line(linewidth = 0.45, na.rm = TRUE) +
    labs(title = title, x = NULL, y = "z-score", colour = NULL) +
    theme_minimal(base_size = 11) +
    theme(legend.position = "bottom", panel.grid.minor = element_blank(), plot.title = element_text(face = "bold"))
}

plot_static_country_stress <- function(cc, from_date = as.Date("2022-01-01")) {
  dfp <- residuals_long %>% filter(country == cc, date >= from_date, !is.na(z_score))
  ggplot(dfp, aes(x = date, y = z_score, colour = market)) +
    geom_hline(yintercept = 0, linetype = "dashed", linewidth = 0.35, colour = "grey45") +
    geom_hline(yintercept = c(-2, 2), linetype = "dotted", linewidth = 0.3, colour = "grey60") +
    geom_line(linewidth = 0.5, na.rm = TRUE) +
    labs(title = paste0("Stress conjunto FX y 10Y — ", cc), x = NULL, y = "z-score", colour = NULL) +
    theme_minimal(base_size = 11) +
    theme(legend.position = "bottom", panel.grid.minor = element_blank(), plot.title = element_text(face = "bold"))
}

plot_static_second_stage <- function(cc) {
  dfp <- second_stage_all %>% filter(country == cc, !is.na(y10_spread), !is.na(z_fx))
  ggplot(dfp, aes(x = y10_spread, y = z_fx)) +
    geom_hline(yintercept = 0, linewidth = 0.3, colour = "grey45") +
    geom_point(alpha = 0.23, size = 0.7, colour = "#27384a") +
    geom_line(aes(y = z_fx_hat), colour = "#7b5e42", linewidth = 0.75) +
    labs(title = paste0("Segunda etapa — ", cc), x = "Diferencial 10Y frente a EE.UU. (p.p.)", y = "z-score residuo FX") +
    theme_minimal(base_size = 11) +
    theme(panel.grid.minor = element_blank(), plot.title = element_text(face = "bold"))
}

plot_static_policy_dashboard <- function(cc) {
  dfp <- dashboard_country_data %>%
    filter(country == cc) %>%
    mutate(panel = factor(panel, levels = c("Tasas (%)", "Desvíos del modelo (z-score)")))
  ggplot(dfp, aes(x = date, y = value, colour = series)) +
    geom_hline(
      data = tibble(panel = factor("Desvíos del modelo (z-score)", levels = levels(dfp$panel))),
      aes(yintercept = 0), inherit.aes = FALSE, linetype = "dashed", linewidth = 0.35, colour = "grey45"
    ) +
    geom_line(linewidth = 0.55, na.rm = TRUE) +
    facet_grid(panel ~ ., scales = "free_y", switch = "y") +
    labs(title = paste0(cc, ": TPM, tasa 10Y y desvíos del modelo"), x = NULL, y = NULL, colour = NULL) +
    theme_minimal(base_size = 11) +
    theme(
      legend.position = "bottom",
      strip.placement = "outside",
      strip.text.y.left = element_text(angle = 0, face = "bold"),
      panel.grid.minor = element_blank(),
      panel.spacing.y = unit(1.4, "lines"),
      plot.title = element_text(face = "bold")
    )
}

report_pdf <- file.path(out_file, "exchange_model_report.pdf")
tryCatch({
  grDevices::pdf(report_pdf, width = 11, height = 8.5, onefile = TRUE)
  plot.new()
  text(0.5, 0.64, "Modelo de tasas y tipo de cambio", cex = 1.55, font = 2)
  text(0.5, 0.56, "FX, tasa soberana 10Y y EMBIG país", cex = 1.05)
  text(0.5, 0.49, paste0("Actualizado: ", latest_date), cex = 0.9, col = "grey35")
  print(plot_static_residuals("FX"))
  print(plot_static_residuals("10Y"))
  for (cc in countries) print(plot_static_policy_dashboard(cc))
  for (cc in countries) {
    print(plot_static_country_stress(cc))
    print(plot_static_second_stage(cc))
  }
  grDevices::dev.off()
}, error = function(e) {
  warning("No se pudo generar el PDF de descarga: ", e$message)
  if (grDevices::dev.cur() > 1) grDevices::dev.off()
})

message("Outputs ExchangeReg generados en: ", out_data)
message("Modelo: FX_EMBI_CPI_BIS | Ultima fecha: ", latest_date)
