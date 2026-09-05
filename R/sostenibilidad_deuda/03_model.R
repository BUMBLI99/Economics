# Debt dynamics and gradual pass-through from market rates to the effective stock rate.

debt_project <- function(initial_debt, assumptions, scenario) {
  assumptions <- dplyr::arrange(assumptions, year)
  stopifnot(nrow(assumptions) > 0, all(1 + assumptions$nominal_growth > 0))
  n <- nrow(assumptions); debt <- lagged <- interest_growth <- numeric(n)
  for (j in seq_len(n)) {
    lagged[j] <- if (j == 1) initial_debt else debt[j - 1]
    interest_growth[j] <- ((1 + assumptions$effective_rate[j]) /
      (1 + assumptions$nominal_growth[j]) - 1) * lagged[j]
    debt[j] <- lagged[j] + interest_growth[j] - assumptions$primary_balance[j] +
      assumptions$total_sfa[j]
  }
  assumptions |>
    dplyr::mutate(
      scenario = scenario, lagged_debt = lagged, interest_growth_effect = interest_growth,
      primary_effect = -primary_balance, sfa_effect = total_sfa,
      debt = debt, debt_change = debt - lagged_debt,
      stabilising_primary_balance = interest_growth_effect + total_sfa,
      primary_gap = primary_balance - stabilising_primary_balance,
      prudent_margin = DEBT_PRUDENT_LEVEL - debt
    )
}

debt_gradual_rate_shock <- function(shock, years, refinancing_share = 0.25) {
  # A permanent market-rate shock reaches the average stock rate only as debt is refinanced.
  stopifnot(refinancing_share > 0, refinancing_share <= 1)
  shock * (1 - (1 - refinancing_share)^seq_along(years))
}

debt_apply_shocks <- function(base, growth = 0, market_rate = 0, primary = 0,
                              sfa = 0, refinancing_share = 0.25) {
  base |>
    dplyr::mutate(
      nominal_growth = nominal_growth + growth,
      effective_rate = effective_rate + debt_gradual_rate_shock(
        market_rate, year, refinancing_share
      ),
      primary_balance = primary_balance + primary,
      valuation_other = valuation_other + sfa,
      total_sfa = identified_sfa + valuation_other + reconciliation
    )
}
