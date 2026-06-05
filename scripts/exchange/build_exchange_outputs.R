# ============================================================
# ExchangeReg: construccion de outputs para sitio web
# Autor: Mauricio Ulloa
# Objetivo: descargar datos, estimar modelos FX/10Y y generar
#           datasets + graficos web para Quarto/GitHub Pages.
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
  "zoo", "purrr", "ggplot2", "readr", "scales"
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
  library(ggplot2)
  library(readr)
  library(scales)
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

needed_env <- c("BCCH_USER", "BCCH_PASS", "FRED_API_KEY")
missing_env <- needed_env[!nzchar(Sys.getenv(needed_env))]
if (length(missing_env) > 0) {
  stop(
    "Faltan variables en .Renviron o en el entorno: ",
    paste(missing_env, collapse = ", "),
    "\nCopia .Renviron.example como .Renviron y completa tus claves."
  )
}

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

monthly_to_daily_log <- function(df_monthly, cal_dates) {
  stopifnot(all(c("date", "value") %in% names(df_monthly)))
  stopifnot("date" %in% names(cal_dates))
  df_monthly <- df_monthly %>% arrange(date) %>% filter(!is.na(value), value > 0)
  if (nrow(df_monthly) < 2) stop("Se necesitan al menos dos observaciones mensuales de CPI.")
  daily_full <- tibble(date = seq(min(df_monthly$date), max(cal_dates$date), by = "day")) %>%
    left_join(df_monthly, by = "date") %>%
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

interp_daily <- function(x) {
  if (all(is.na(x))) return(x)
  zoo::na.locf(zoo::na.approx(x, na.rm = FALSE), na.rm = FALSE)
}

rmse <- function(x) sqrt(mean(x^2, na.rm = TRUE))

model_summary_row <- function(model, country, block) {
  tibble(
    country = country,
    block = block,
    n_obs = length(stats::resid(model)),
    r2 = unname(summary(model)$r.squared),
    adj_r2 = unname(summary(model)$adj.r.squared),
    rmse = rmse(stats::resid(model))
  )
}

# ------------------------------------------------------------
# Descarga de datos
# ------------------------------------------------------------
message("Descargando tasas soberanas BCCh...")
y10_clp <- bde_get_series(bde_user, bde_pass, "F022.BCLP.TIS.AN10.NO.Z.D", start_date, end_date) %>% rename(y10_clp = value_num)
y10_brl <- bde_get_series(bde_user, bde_pass, "F019.TBG.TAS.BRA.D",       start_date, end_date) %>% rename(y10_brl = value_num)
y10_mxn <- bde_get_series(bde_user, bde_pass, "F019.TBG.TAS.MEX.D",       start_date, end_date) %>% rename(y10_mxn = value_num)
y10_pen <- bde_get_series(bde_user, bde_pass, "F019.TBG.TAS.PER.D",       start_date, end_date) %>% rename(y10_pen = value_num)
y10_col <- bde_get_series(bde_user, bde_pass, "F019.TBG.TAS.COL.D",       start_date, end_date) %>% rename(y10_col = value_num)
y10_us  <- bde_get_series(bde_user, bde_pass, "F019.TBG.TAS.10.D",        start_date, end_date) %>% rename(y10_us = value_num)

message("Descargando commodities/equity BCCh y FRED...")
copper <- bde_get_series(bde_user, bde_pass, "F019.PPB.PRE.100.D", start_date, end_date) %>% rename(copper = value_num)
eq_nsq <- bde_get_series(bde_user, bde_pass, "F019.IBC.IND.51.D",  start_date, end_date) %>% rename(eq_nsq = value_num)
eq_cny <- bde_get_series(bde_user, bde_pass, "F019.IBC.IND.CHN.D", start_date, end_date) %>% rename(eq_cny = value_num)
wti    <- fred_get_series(fred_api_key, "DCOILWTICO", start_date, end_date) %>% rename(wti = value_num)
vix    <- fred_get_series(fred_api_key, "VIXCLS",     start_date, end_date) %>% rename(vix = value_num)

message("Descargando BIS FX/EER/CPI...")
dtw <- bis_get_daily("WS_EER", "D.N.B.US", start_date, end_date) %>% rename(dtw = value_num)
fx_clp <- bis_get_daily("WS_XRU", "D.CL.CLP.A", start_date, end_date) %>% rename(fx_clp = value_num)
fx_brl <- bis_get_daily("WS_XRU", "D.BR.BRL.A", start_date, end_date) %>% rename(fx_brl = value_num)
fx_cny <- bis_get_daily("WS_XRU", "D.CN.CNY.A", start_date, end_date) %>% rename(cny_usd = value_num)
fx_mxn <- bis_get_daily("WS_XRU", "D.MX.MXN.A", start_date, end_date) %>% rename(fx_mxn = value_num)
fx_pen <- bis_get_daily("WS_XRU", "D.PE.PEN.A", start_date, end_date) %>% rename(fx_pen = value_num)
fx_cop <- bis_get_daily("WS_XRU", "D.CO.COP.A", start_date, end_date) %>% rename(fx_cop = value_num)

cpi_specs <- tribble(
  ~country, ~series_key,
  "CLP", "M.CL.628",
  "US",  "M.US.628",
  "BRL", "M.BR.628",
  "COP", "M.CO.628",
  "MXN", "M.MX.628",
  "PEN", "M.PE.628"
)
cpi_monthly <- cpi_specs %>%
  mutate(data = map(series_key, ~ bis_get_long_cpi_monthly(.x, start_date, end_date)))

cal_trading <- fx_clp %>% select(date) %>% distinct() %>% arrange(date)

cpi_daily_wide <- cpi_monthly %>%
  mutate(daily = map(data, ~ monthly_to_daily_log(.x, cal_trading))) %>%
  select(country, daily) %>%
  tidyr::unnest(daily) %>%
  tidyr::pivot_wider(names_from = country, values_from = value_daily, names_prefix = "cpi_") %>%
  arrange(date)

cpi_sources <- cpi_monthly %>%
  transmute(
    country,
    series_key,
    first_date = map_chr(data, ~ as.character(min(.x$date, na.rm = TRUE))),
    last_date  = map_chr(data, ~ as.character(max(.x$date, na.rm = TRUE))),
    n_months   = map_int(data, nrow)
  )
readr::write_csv(cpi_sources, file.path(out_data, "cpi_sources.csv"))

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
  left_join(eq_nsq,  by = "date") %>%
  left_join(eq_cny,  by = "date") %>%
  left_join(dtw,     by = "date") %>%
  left_join(vix,     by = "date") %>%
  left_join(wti,     by = "date") %>%
  left_join(copper,  by = "date") %>%
  left_join(cpi_daily_wide, by = "date") %>%
  arrange(date)

vars_daily_interp <- c(
  "fx_clp", "fx_brl", "fx_mxn", "fx_pen", "fx_cop", "cny_usd",
  "y10_clp", "y10_brl", "y10_mxn", "y10_pen", "y10_col", "y10_us",
  "wti", "copper", "eq_nsq", "eq_cny", "dtw", "vix"
)

db_daily <- db_daily %>%
  arrange(date) %>%
  mutate(across(all_of(vars_daily_interp), interp_daily)) %>%
  mutate(
    trend = row_number(),
    log_cpi_rel_chl_us = log(cpi_CLP / cpi_US),
    log_cpi_rel_bra_us = log(cpi_BRL / cpi_US),
    log_cpi_rel_mex_us = log(cpi_MXN / cpi_US),
    log_cpi_rel_per_us = log(cpi_PEN / cpi_US),
    log_cpi_rel_col_us = log(cpi_COP / cpi_US),
    l_wti   = if_else(wti > 0, log(wti), NA_real_),
    l_pcu   = if_else(copper > 0, log(copper), NA_real_),
    l_eqnsq = if_else(eq_nsq > 0, log(eq_nsq), NA_real_),
    l_eqcny = if_else(eq_cny > 0, log(eq_cny), NA_real_),
    l_vix   = if_else(vix > 0, log(vix), NA_real_),
    l_dtw   = if_else(dtw > 0, log(dtw), NA_real_),
    l_cny   = if_else(cny_usd > 0, log(cny_usd), NA_real_)
  )

# ------------------------------------------------------------
# Modelos
# ------------------------------------------------------------
run_fx_model <- function(df, country_code, fx_var, cpi_rel_var) {
  df_model <- df %>%
    transmute(
      date,
      l_fx = if_else(.data[[fx_var]] > 0, log(.data[[fx_var]]), NA_real_),
      trend,
      cpi_rel = .data[[cpi_rel_var]],
      l_wti, l_pcu, l_eqnsq, l_eqcny, l_vix, l_dtw, l_cny
    ) %>%
    drop_na()
  mod <- lm(l_fx ~ trend + cpi_rel + l_wti + l_pcu + l_eqnsq + l_eqcny + l_vix + l_dtw + l_cny,
            data = df_model)
  res <- resid(mod)
  df_model %>%
    mutate(res_fx = res, z_res_fx = as.numeric(scale(res_fx))) %>%
    select(date, res_fx, z_res_fx) -> residuals
  list(country = country_code, model = mod, residuals = residuals)
}

run_yield_model <- function(df, country_code, y10_var) {
  df_model <- df %>%
    transmute(date, y10 = .data[[y10_var]], y10_us = y10_us, trend, l_vix, l_eqnsq, l_dtw, l_cny) %>%
    drop_na()
  mod <- lm(y10 ~ y10_us + l_vix + l_eqnsq + l_dtw + l_cny + trend, data = df_model)
  res <- resid(mod)
  df_model %>%
    mutate(res_y10 = res, z_res_y10 = as.numeric(scale(res_y10))) %>%
    select(date, res_y10, z_res_y10) -> residuals
  list(country = country_code, model = mod, residuals = residuals)
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
  ~country, ~y10_var,
  "CLP", "y10_clp",
  "BRL", "y10_brl",
  "MXN", "y10_mxn",
  "PEN", "y10_pen",
  "COP", "y10_col"
)

message("Estimando modelos FX y 10Y...")
fx_results <- fx_specs %>% mutate(result = pmap(list(country, fx_var, cpi_rel_var), ~ run_fx_model(db_daily, ..1, ..2, ..3)))
yield_results <- yield_specs %>% mutate(result = map2(country, y10_var, ~ run_yield_model(db_daily, .x, .y)))

fx_models <- setNames(lapply(fx_results$result, `[[`, "model"), fx_specs$country)
yield_models <- setNames(lapply(yield_results$result, `[[`, "model"), yield_specs$country)

fx_residuals_all <- map_dfr(fx_results$result, ~ .x$residuals %>% mutate(country = .x$country))
yield_residuals_all <- map_dfr(yield_results$result, ~ .x$residuals %>% mutate(country = .x$country))

fx_residuals_wide <- fx_residuals_all %>% select(date, country, z_res_fx) %>% pivot_wider(names_from = country, values_from = z_res_fx, names_prefix = "z_res_fx_")
yield_residuals_wide <- yield_residuals_all %>% select(date, country, z_res_y10) %>% pivot_wider(names_from = country, values_from = z_res_y10, names_prefix = "z_res_y10_")

db_daily <- db_daily %>%
  left_join(fx_residuals_wide, by = "date") %>%
  left_join(yield_residuals_wide, by = "date")

fit_summary <- bind_rows(
  imap_dfr(fx_models, ~ model_summary_row(.x, .y, "FX")),
  imap_dfr(yield_models, ~ model_summary_row(.x, .y, "10Y"))
) %>%
  mutate(across(c(r2, adj_r2, rmse), ~ round(.x, 4)))

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
) %>%
  mutate(across(c(estimate, std_error, statistic, p_value), ~ signif(.x, 5)))

# ------------------------------------------------------------
# Segunda etapa
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
  df_model <- df_model %>% mutate(z_fx_hat = fitted(mod), res_2nd = resid(mod))
  list(country = country_code, model = mod, data = df_model)
}

second_stage_results <- yield_specs %>% mutate(result = map2(country, y10_var, ~ run_second_stage_fx_y10(db_daily, .x, .y)))
second_stage_models <- setNames(lapply(second_stage_results$result, `[[`, "model"), yield_specs$country)
second_stage_all <- map_dfr(second_stage_results$result, ~ .x$data %>% mutate(country = .x$country))

second_stage_summary <- imap_dfr(second_stage_models, function(mod, cc) {
  coefs <- summary(mod)$coefficients
  tibble(
    country = cc,
    beta_y10_spread = unname(coefs["y10_spread", "Estimate"]),
    p_value = unname(coefs["y10_spread", "Pr(>|t|)"]),
    r2 = unname(summary(mod)$r.squared),
    n_obs = length(resid(mod))
  )
}) %>%
  mutate(
    beta_y10_spread = round(beta_y10_spread, 4),
    p_value = signif(p_value, 3),
    r2 = round(r2, 4),
    lectura = case_when(
      r2 >= 0.12 ~ "relacion positiva mas marcada",
      r2 >= 0.05 ~ "relacion positiva relevante",
      r2 >= 0.01 ~ "relacion debil",
      TRUE ~ "relacion practicamente nula"
    )
  )

# ------------------------------------------------------------
# Datasets para Quarto
# ------------------------------------------------------------
residuals_long <- bind_rows(
  fx_residuals_all %>% transmute(date, country, market = "FX", z_score = z_res_fx),
  yield_residuals_all %>% transmute(date, country, market = "10Y", z_score = z_res_y10)
) %>% arrange(market, country, date)

latest_date <- max(residuals_long$date, na.rm = TRUE)
latest_snapshot <- residuals_long %>%
  filter(date == latest_date) %>%
  select(date, country, market, z_score) %>%
  pivot_wider(names_from = market, values_from = z_score) %>%
  arrange(country) %>%
  mutate(across(c(FX, `10Y`), ~ round(.x, 2)))

readr::write_csv(db_daily, file.path(out_data, "db_daily_exchange.csv"))
readr::write_csv(residuals_long, file.path(out_data, "residuals_long.csv"))
readr::write_csv(fit_summary, file.path(out_data, "model_fit_summary.csv"))
readr::write_csv(model_coefficients, file.path(out_data, "model_coefficients.csv"))
readr::write_csv(second_stage_summary, file.path(out_data, "second_stage_summary.csv"))
readr::write_csv(second_stage_all, file.path(out_data, "second_stage_data.csv"))
readr::write_csv(latest_snapshot, file.path(out_data, "latest_snapshot.csv"))

metadata <- tibble(
  item = c("start_date", "end_date", "latest_model_date", "created_at"),
  value = c(start_date, end_date, as.character(latest_date), as.character(Sys.time()))
)
readr::write_csv(metadata, file.path(out_data, "metadata.csv"))

# ------------------------------------------------------------
# Graficos web
# ------------------------------------------------------------
country_colors <- c(
  "CLP" = "#E67E22",
  "BRL" = "#3fb1d3",
  "MXN" = "#006400",
  "PEN" = "#F1C40F",
  "COP" = "#084e89"
)

mu_theme <- function() {
  theme_minimal(base_size = 13) +
    theme(
      plot.title = element_text(face = "bold", colour = "#27384a", size = 17),
      plot.subtitle = element_text(colour = "#66717f", size = 11),
      axis.title = element_text(colour = "#27384a", face = "bold"),
      axis.text = element_text(colour = "#4e5965"),
      legend.position = "bottom",
      legend.title = element_blank(),
      panel.grid.minor = element_blank(),
      plot.background = element_rect(fill = "white", colour = NA),
      panel.background = element_rect(fill = "white", colour = NA)
    )
}

plot_global_res <- function(df, market = c("FX", "10Y"), from_date = as.Date("2022-01-01")) {
  market <- match.arg(market)
  ylab <- if (market == "FX") "z-score residuo FX" else "z-score residuo 10Y"
  title <- if (market == "FX") "Residuos normalizados del tipo de cambio" else "Residuos normalizados de tasas soberanas 10Y"
  dfp <- df %>% filter(.data$market == .env$market, date >= from_date)
  ggplot(dfp, aes(date, z_score, colour = country)) +
    geom_hline(yintercept = 0, linewidth = 0.35, linetype = "dashed", colour = "#8a94a3") +
    geom_hline(yintercept = c(-2, 2), linewidth = 0.25, linetype = "dotted", colour = "#c8c0b3") +
    geom_line(linewidth = 0.55, alpha = 0.95) +
    scale_color_manual(values = country_colors) +
    scale_x_date(labels = scales::label_date("%Y"), breaks = scales::breaks_pretty(7)) +
    labs(title = title, subtitle = "Desviaciones respecto de fundamentos externos observables", x = NULL, y = ylab) +
    mu_theme()
}

plot_stress_country <- function(df, country_code, from_date = as.Date("2022-01-01")) {
  fx_col  <- paste0("z_res_fx_",  country_code)
  y10_col <- paste0("z_res_y10_", country_code)
  df_plot <- df %>%
    filter(date >= from_date) %>%
    select(date, z_fx = all_of(fx_col), z_y10 = all_of(y10_col)) %>%
    pivot_longer(c(z_fx, z_y10), names_to = "serie", values_to = "z_score") %>%
    mutate(serie = recode(serie, z_fx = "FX residual", z_y10 = "10Y residual"))
  ggplot(df_plot, aes(date, z_score, colour = serie)) +
    geom_hline(yintercept = 0, linewidth = 0.35, linetype = "dashed", colour = "#8a94a3") +
    geom_hline(yintercept = c(-2, 2), linewidth = 0.25, linetype = "dotted", colour = "#c8c0b3") +
    geom_line(linewidth = 0.55) +
    scale_color_manual(values = c("FX residual" = "#27384a", "10Y residual" = "#7b5e42")) +
    labs(title = paste("Stress FX y 10Y -", country_code), subtitle = "Residuos normalizados por mercado", x = NULL, y = "z-score") +
    mu_theme()
}

plot_second_stage_country <- function(second_stage_results, country_code) {
  obj <- second_stage_results$result[[which(second_stage_results$country == country_code)]]
  dfp <- obj$data
  sm <- summary(obj$model)
  beta <- unname(coef(obj$model)["y10_spread"])
  ggplot(dfp, aes(y10_spread, z_fx)) +
    geom_point(alpha = 0.30, size = 0.65, colour = "#27384a") +
    geom_smooth(method = "lm", se = FALSE, linewidth = 0.8, colour = "#7b5e42") +
    labs(
      title = paste("Segunda etapa FX vs spread 10Y -", country_code),
      subtitle = paste0("Coeficiente = ", round(beta, 3), " · R² = ", round(sm$r.squared, 3)),
      x = "Diferencial 10Y frente a EE.UU. (p.p.)",
      y = "z-score residuo FX"
    ) +
    mu_theme()
}

save_plot <- function(plot, filename, width = 13, height = 5.6) {
  ggsave(file.path(out_img, filename), plot = plot, width = width, height = height, dpi = 190, bg = "white")
}

# Graficos panoramicos para integracion web: menos alto, mas ancho y legibles en tarjetas.
save_plot(plot_global_res(residuals_long, "FX"),  "fx_residuals_zscores_from2018.jpg",  width = 14.5, height = 5.7)
save_plot(plot_global_res(residuals_long, "10Y"), "y10_residuals_zscores_from2018.jpg", width = 14.5, height = 5.7)

for (cc in fx_specs$country) {
  save_plot(plot_stress_country(db_daily, cc), paste0("stress_fx_y10_", cc, ".jpg"), width = 14.2, height = 5.5)
  save_plot(plot_second_stage_country(second_stage_results, cc), paste0("second_stage_fx_y10_", cc, ".jpg"), width = 13.2, height = 5.9)
}

message("Outputs ExchangeReg actualizados en:")
message(" - ", out_data)
message(" - ", out_img)
