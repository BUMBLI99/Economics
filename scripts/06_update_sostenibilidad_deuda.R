#!/usr/bin/env Rscript

find_root <- function(start = getwd()) {
  path <- normalizePath(start, winslash = "/", mustWork = TRUE)
  repeat {
    setup <- file.path(path, "R", "sostenibilidad_deuda", "00_setup.R")
    if (file.exists(setup)) return(path)
    parent <- dirname(path)
    if (identical(parent, path)) stop("No se encontró R/sostenibilidad_deuda/00_setup.R")
    path <- parent
  }
}

root <- find_root()
source(file.path(root, "R", "sostenibilidad_deuda", "00_setup.R"), encoding = "UTF-8")
debt_load_packages()
source(debt_path("R", "sostenibilidad_deuda", "01_data.R", root = root), encoding = "UTF-8")
source(debt_path("R", "sostenibilidad_deuda", "02_accounts.R", root = root), encoding = "UTF-8")
source(debt_path("R", "sostenibilidad_deuda", "03_model.R", root = root), encoding = "UTF-8")
source(debt_path("R", "sostenibilidad_deuda", "04_scenarios.R", root = root), encoding = "UTF-8")
source(debt_path("R", "sostenibilidad_deuda", "05_exports.R", root = root), encoding = "UTF-8")

inputs <- debt_read_inputs(root)
debt_validate_inputs(inputs)
accounts <- debt_build_accounts(inputs)
model <- debt_run_scenarios(inputs, accounts)
debt_export_results(model, root)

dir.create(debt_path("data", "processed", "sostenibilidad_deuda", root = root),
           recursive = TRUE, showWarnings = FALSE)
readr::write_csv(accounts$checks,
  debt_path("data", "processed", "sostenibilidad_deuda",
            "control_identidad_financiamiento_modular.csv", root = root))

message("Validación fiscal completada. Identidad de financiamiento: OK.")
