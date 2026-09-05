# Calibrate the official paths and construct transparent conditional scenarios.

debt_calibrate_paths <- function(inputs, accounts) {
  panel <- inputs$official_debt |>
    dplyr::select(year, committed_debt, target_debt, prudent_level, status) |>
    dplyr::left_join(accounts$macro |> dplyr::select(year, nominal_gdp, nominal_growth), by = "year") |>
    dplyr::left_join(accounts$balance |> dplyr::select(
      year, interest_mm, committed_primary, target_primary, committed_overall, target_balance
    ), by = "year") |>
    dplyr::left_join(accounts$financing, by = "year") |>
    dplyr::arrange(year) |>
    dplyr::mutate(
      target_debt = dplyr::coalesce(target_debt, committed_debt),
      committed_stock = committed_debt * nominal_gdp,
      target_stock = target_debt * nominal_gdp,
      lagged_committed_stock = dplyr::lag(committed_stock),
      lagged_target_stock = dplyr::lag(target_stock),
      lagged_committed_debt = dplyr::lag(committed_debt),
      lagged_target_debt = dplyr::lag(target_debt),
      committed_rate = interest_mm / lagged_committed_stock,
      target_rate = interest_mm / lagged_target_stock,
      identified_sfa = net_financial_operations / nominal_gdp,
      valuation_other = ((committed_stock - lagged_committed_stock) - net_issuance) / nominal_gdp,
      committed_total_sfa = identified_sfa + valuation_other,
      target_without_reconciliation = ((1 + target_rate) / (1 + nominal_growth)) *
        lagged_target_debt - target_primary + identified_sfa + valuation_other,
      reconciliation = target_debt - target_without_reconciliation,
      target_total_sfa = identified_sfa + valuation_other + reconciliation
    )
  committed_error <- panel |>
    dplyr::filter(year >= 2026) |>
    dplyr::transmute(error = committed_debt - (((1 + committed_rate) / (1 + nominal_growth)) *
      lagged_committed_debt - committed_primary + committed_total_sfa)) |>
    dplyr::summarise(max_error = max(abs(error), na.rm = TRUE)) |>
    dplyr::pull(max_error)
  if (committed_error > 1e-8) stop("La reconstrucción de la senda comprometida no cierra.")
  if (max(abs(panel$reconciliation[panel$year >= 2027]), na.rm = TRUE) > 0.0025) {
    stop("La conciliación de la senda compatible supera 0,25 pp del PIB.")
  }
  panel
}

debt_run_scenarios <- function(inputs, accounts) {
  panel <- debt_calibrate_paths(inputs, accounts)
  official_base <- panel |>
    dplyr::filter(year >= 2027, year <= 2030) |>
    dplyr::transmute(year, nominal_growth, effective_rate = target_rate,
      primary_balance = target_primary, identified_sfa, valuation_other,
      reconciliation, total_sfa = target_total_sfa, official_debt = target_debt,
      nature = "Calibración a trayectoria oficial compatible con la meta")
  extension <- inputs$extension |>
    dplyr::transmute(year, nominal_growth, effective_rate, primary_balance,
      identified_sfa, valuation_other, reconciliation = 0,
      total_sfa = identified_sfa + valuation_other, official_debt = NA_real_, nature)
  base <- dplyr::bind_rows(official_base, extension) |> dplyr::arrange(year)
  initial <- panel$target_debt[panel$year == 2026]

  conditional <- purrr::pmap_dfr(
    inputs$scenarios,
    function(scenario, growth_shock, market_rate_shock, primary_shock,
             sfa_shock, refinancing_share, special_treatment, interpretation) {
      assumptions <- debt_apply_shocks(
        base, growth = growth_shock, market_rate = market_rate_shock,
        primary = primary_shock, sfa = sfa_shock,
        refinancing_share = refinancing_share
      )
      debt_project(initial, assumptions, scenario)
    }
  )
  committed_assumptions <- panel |>
    dplyr::filter(year >= 2027, year <= 2030) |>
    dplyr::transmute(year, nominal_growth, effective_rate = committed_rate,
      primary_balance = committed_primary, identified_sfa, valuation_other,
      reconciliation = 0, total_sfa = committed_total_sfa,
      official_debt = committed_debt, nature = "Trayectoria oficial con gasto comprometido")
  committed <- debt_project(
    panel$committed_debt[panel$year == 2026], committed_assumptions,
    "Gasto comprometido (oficial)"
  )

  results <- dplyr::bind_rows(
    conditional |> dplyr::filter(scenario == "Base compatible con la meta"),
    committed,
    conditional |> dplyr::filter(scenario != "Base compatible con la meta")
  )
  list(panel = panel, base = base, results = results)
}
