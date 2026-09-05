# Reconstruct official stocks and flows without hiding residual reconciliation.

debt_build_accounts <- function(x) {
  macro <- x$macro |>
    dplyr::arrange(year) |>
    dplyr::mutate(nominal_growth = nominal_gdp / dplyr::lag(nominal_gdp) - 1)
  balance <- x$balance |>
    dplyr::left_join(macro |> dplyr::select(year, nominal_gdp), by = "year") |>
    dplyr::mutate(
      interest_gdp = interest_mm / nominal_gdp,
      committed_overall = committed_balance_mm / nominal_gdp,
      committed_primary = committed_overall + interest_gdp,
      target_primary = target_balance + interest_gdp
    )
  financing <- x$financing |>
    tidyr::pivot_longer(dplyr::starts_with("y"), names_to = "year", values_to = "value") |>
    dplyr::mutate(year = as.integer(sub("y", "", year))) |>
    dplyr::group_by(year) |>
    dplyr::summarise(
      deficit = sum(value[dsa_class == "Déficit"], na.rm = TRUE),
      amortisation = sum(value[dsa_class == "Amortización"], na.rm = TRUE),
      issuance = sum(value[dsa_class == "Emisión"], na.rm = TRUE),
      below_line = sum(value[dsa_class == "Bajo la línea"], na.rm = TRUE),
      asset_financing = sum(value[dsa_class == "Financiamiento con activos"], na.rm = TRUE),
      financing_needs = sum(value[component == "Necesidades de financiamiento"], na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::mutate(net_financial_operations = below_line - asset_financing,
                  net_issuance = issuance - amortisation)
  checks <- financing |>
    dplyr::transmute(year, uses = deficit + amortisation + below_line,
                     sources = issuance + asset_financing,
                     identity_error = uses - sources,
                     needs_error = financing_needs - uses)
  if (any(abs(checks$identity_error) > 2) || any(abs(checks$needs_error) > 2)) {
    stop("La identidad de necesidades de financiamiento no cierra.")
  }
  list(macro = macro, balance = balance, financing = financing, checks = checks)
}
