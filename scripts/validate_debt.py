"""Independent arithmetic and publication checks; does not replace source verification."""
import json
from pathlib import Path
import pandas as pd
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
data = ROOT / 'data/processed/sostenibilidad_deuda'
d = pd.read_csv(data / 'trayectorias_escenarios.csv')
assert not d.duplicated(['escenario', 'anio']).any()
calculated = (1 + d.tasa_efectiva) / (1 + d.crecimiento_nominal) * d.deuda_rezagada - d.balance_primario + d.sfa_total
assert np.allclose(calculated, d.deuda_pib, atol=1e-10, rtol=0)
assert np.allclose(d.cambio_deuda, d.efecto_interes_crecimiento + d.efecto_balance_primario + d.efecto_sfa, atol=1e-10)
assert np.allclose(d.balance_primario_estabilizador - d.balance_primario, d.cambio_deuda, atol=1e-10)
assert np.allclose(d.sfa_total, d.sfa_identificado + d.valorizacion_otros + d.ajuste_conciliacion, atol=1e-10)
base = d[d.escenario.eq('Base compatible con la meta')].sort_values('anio')
shocks = pd.read_csv(ROOT / 'data/raw/sostenibilidad_deuda/escenarios.csv')
for shock in shocks.itertuples():
    stock = float(base.iloc[0].deuda_rezagada)
    expected = []
    for index, row in enumerate(base.itertuples(), 1):
        rate = row.tasa_efectiva + shock.market_rate_shock * (1 - (1 - shock.refinancing_share) ** index)
        growth = row.crecimiento_nominal + shock.growth_shock
        stock = (1 + rate) / (1 + growth) * stock - row.balance_primario - shock.primary_shock + row.sfa_total + shock.sfa_shock
        expected.append(stock)
    actual = d[d.escenario.eq(shock.scenario)].sort_values('anio')
    assert np.allclose(expected, actual.deuda_pib, atol=1e-10, rtol=0), shock.scenario
summary = pd.read_csv(data / 'resumen_escenarios.csv')
for row in summary.itertuples():
    path = d[d.escenario.eq(row.escenario)].set_index('anio')
    assert abs(path.loc[2030, 'deuda_pib'] - row.deuda_2030) < 1e-10
    assert abs(path.deuda_pib.max() - row.deuda_maxima) < 1e-10
    crossing = path[path.deuda_pib.gt(.45)]
    assert (crossing.empty and pd.isna(row.primer_anio_sobre_45)) or (not crossing.empty and crossing.index.min() == row.primer_anio_sobre_45)
official = pd.read_csv(ROOT / 'data/raw/sostenibilidad_deuda/deuda_oficial.csv').set_index('year')
for scenario, column in [('Base compatible con la meta', 'target_debt'), ('Gasto comprometido (oficial)', 'committed_debt')]:
    rows = d[d.escenario.eq(scenario) & d.anio.le(2030)]
    assert np.allclose(rows.deuda_pib, official.loc[rows.anio, column], atol=1e-10)
history = pd.read_csv(ROOT / 'data/raw/sostenibilidad_deuda/deuda_historica.csv')
assert history.year.tolist() == list(range(1990, 2026))
assert abs(history.iloc[-1].debt - official.loc[2025, 'committed_debt']) < 1e-10
checks = pd.read_csv(data / 'control_identidad_financiamiento.csv')
assert checks[['diferencia_mm', 'diferencia_necesidades_mm']].abs().max().max() < 2
print('Financing identity: OK (tolerance 2 million CLP).')
payload = json.loads((ROOT / 'site/assets/data/project_charts.json').read_text())['debt']
chart = payload['datasets'][0]
assert chart['series'][0]['values'][0]['label'] == '1990'
assert chart['xTicks'][-1]['label'] == '2035'
assert chart['referenceLines'][0]['value'] == 45
assert any(x['id'] == 'primary' for x in payload['datasets'])
print('OK: debt identity, decomposition, stabilising balance, official paths, history and web metadata.')
