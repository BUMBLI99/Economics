# Read official inputs and enforce units, signs and accounting identities.

debt_read_inputs <- function(root = debt_find_root()) {
  input_dir <- debt_path("data", "raw", "sostenibilidad_deuda", root = root)
  read_input <- function(filename) {
    readr::read_csv(file.path(input_dir, filename), show_col_types = FALSE,
                    na = c("", "NA"))
  }
  list(
    history = read_input("deuda_historica.csv"),
    macro = read_input("macro_ifp.csv"),
    official_debt = read_input("deuda_oficial.csv"),
    balance = read_input("balance_ifp.csv"),
    financing = read_input("financiamiento_ifp.csv"),
    extension = read_input("supuestos_2031_2035.csv"),
    scenarios = read_input("escenarios.csv")
  )
}

debt_validate_inputs <- function(x) {
  expected_scenarios <- c(
    "Base compatible con la meta", "Menor crecimiento",
    "Mayor tasa de interés", "Menor esfuerzo fiscal", "Combinación adversa"
  )
  stopifnot(
    !anyDuplicated(x$history$year), !anyDuplicated(x$macro$year),
    !anyDuplicated(x$official_debt$year),
    all(2025:2030 %in% x$official_debt$year), all(2026:2030 %in% x$balance$year),
    all(abs(x$official_debt$prudent_level - DEBT_PRUDENT_LEVEL) < 1e-12),
    all(is.finite(x$history$debt)), all(x$history$debt >= 0),
    all(abs(x$extension$total_sfa_excel -
      (x$extension$identified_sfa + x$extension$valuation_other)) < 1e-12),
    setequal(x$scenarios$scenario, expected_scenarios),
    all(x$scenarios$refinancing_share > 0 & x$scenarios$refinancing_share <= 1)
  )
  invisible(x)
}
