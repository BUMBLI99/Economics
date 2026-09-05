# Regression tests with synthetic data; no credentials or network required.
suppressPackageStartupMessages({library(dplyr); library(tidyr); library(lubridate)})
source("R/imacec_config.R")
source("R/imacec_models.R")
source("R/imacec_outputs.R")
source("R/imacec_data.R")
set.seed(610)
n <- 91L
data <- tibble::tibble(Periodo = seq(as.Date("2019-01-01"), by = "month", length.out = n))
for (v in setdiff(model_required_variables("m8p", "total", TRUE), "Periodo")) data[[v]] <- rnorm(n)
data$imacec_no_minero <- rnorm(n)
data$imacec_no_minero_lag1 <- dplyr::lag(data$imacec_no_minero)
data$imacec_total_lag1 <- dplyr::lag(data$imacec_total)
period <- data$Periodo[n]
eee <- tibble::tibble(Periodo = period, survey_period = period %m+% months(1), eee_imacec = 1, eee_imacec_nm = 1)
for (target in names(target_specs)) {
  complete <- run_nowcast("m8p", target, period, data, eee)
  stopifnot(nrow(complete$proyeccion) == 1L, all(complete$history$Periodo < period),
            all(is.finite(complete$history$fitted)))
  incomplete <- data
  incomplete[n, c("mineria", "manufactura", "electricidad")] <- NA_real_
  result <- run_nowcast("m8p", target, period, incomplete, eee)
  stopifnot(nrow(result$proyeccion) == 0L, nrow(result$history) == nrow(complete$history),
            identical(result$history$fitted, complete$history$fitted))
  # Extreme target observations must not leak into the historical estimation.
  extreme <- data
  extreme[n, target_specs[[target]]$response] <- 1e6
  stopifnot(identical(run_nowcast("m8p", target, period, extreme, eee)$history$fitted, complete$history$fitted))
}
fixture <- tibble::tibble(Periodo = as.Date("2026-07-01"), mineria = NA_real_, manufactura = 12, electricidad = NA_real_)
before <- apply_ine_yoy_fallback(fixture, as_of = as.Date("2026-08-30"))
after <- apply_ine_yoy_fallback(fixture, as_of = as.Date("2026-08-31"))
stopifnot(is.na(before$mineria), after$mineria == -7.2, after$manufactura == 12, after$electricidad == .3)
message("OK: target missingness preserves fits; no target leakage; dated INE fallback never overwrites BDE.")
