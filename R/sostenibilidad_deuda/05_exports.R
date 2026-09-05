# Stable contract between the analytical model and the static publication.

debt_export_results <- function(model, root = debt_find_root()) {
  out <- debt_path("data", "processed", "sostenibilidad_deuda", root = root)
  dir.create(out, recursive = TRUE, showWarnings = FALSE)
  results <- model$results |>
    dplyr::mutate(anio = year, escenario = scenario, deuda_pib = debt,
      deuda_rezagada = lagged_debt,
      efecto_interes_crecimiento = interest_growth_effect,
      efecto_balance_primario = primary_effect, efecto_sfa = sfa_effect,
      efecto_sfa_identificado = identified_sfa,
      efecto_valorizacion_otros = valuation_other,
      efecto_ajuste_conciliacion = reconciliation,
      crecimiento_nominal = nominal_growth, tasa_efectiva = effective_rate,
      balance_primario = primary_balance, sfa_identificado = identified_sfa,
      valorizacion_otros = valuation_other, ajuste_conciliacion = reconciliation,
      sfa_total = total_sfa)
  summary <- results |>
    dplyr::group_by(escenario) |>
    dplyr::summarise(
      deuda_2030 = deuda_pib[anio == 2030][1],
      deuda_2035 = if (any(anio == 2035)) deuda_pib[anio == 2035][1] else NA_real_,
      deuda_maxima = max(deuda_pib, na.rm = TRUE),
      anio_maximo = anio[which.max(deuda_pib)][1],
      primer_anio_sobre_45 = if (any(deuda_pib > DEBT_PRUDENT_LEVEL))
        min(anio[deuda_pib > DEBT_PRUDENT_LEVEL]) else NA_integer_,
      distancia_45_en_2030 = DEBT_PRUDENT_LEVEL - deuda_2030, .groups = "drop")
  readr::write_csv(results, file.path(out, "trayectorias_escenarios.csv"))
  readr::write_csv(summary, file.path(out, "resumen_escenarios.csv"))
  invisible(list(results = results, summary = summary))
}
