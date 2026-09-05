"""Debt-only publication layer: preserve observed history and explicit scenario dates."""
from pathlib import Path
import pandas as pd
import matplotlib.pyplot as plt

ROOT = Path(__file__).resolve().parents[1]


def enrich_debt_chart(charts, debt):
    history = pd.read_csv(ROOT / 'data/raw/sostenibilidad_deuda/deuda_historica.csv')
    official = pd.read_csv(ROOT / 'data/raw/sostenibilidad_deuda/deuda_oficial.csv')
    datasets = charts['debt']['datasets']
    trajectories = datasets[0]
    colors = ['#193044', '#b28a4a', '#2b7777', '#76658c', '#416c8a', '#b4573d']

    def point(year, value):
        return {'date': f'{int(year)}-01-01', 'label': str(int(year)), 'value': round(100 * value, 4)}

    observed = {'name': 'Historia efectiva · 1990–2025', 'color': '#193044', 'width': 3.3,
                'values': [point(r.year, r.debt) for r in history.itertuples()]}
    # 2026 is a forecast anchor, not an observed value or a shocked simulation year.
    for series in trajectories['series']:
        column = 'committed_debt' if series['name'] == 'Gasto comprometido (oficial)' else 'target_debt'
        anchors = [point(2025, history.iloc[-1].debt),
                   point(2026, official.loc[official.year.eq(2026), column].iloc[0])]
        series['values'] = anchors + series['values']
        series['dash'] = '7 4' if column == 'target_debt' else '3 3'
    forecast_series = trajectories['series']
    ref = [{'value': 45, 'label': 'Nivel prudente · 45% del PIB'}]
    regions = [
        {'start': '2025-01-01', 'end': '2030-01-01', 'label': 'Proyección', 'color': '#eef3f5'},
        {'start': '2030-01-01', 'end': '2035-01-01', 'label': 'Extensión', 'color': '#f8eee8'},
    ]
    def ticks(years):
        return [{'date': f'{y}-01-01', 'label': str(y)} for y in years]

    trajectories.update(label='Historia y escenarios · 1990–2035', series=[observed] + forecast_series,
                        minY=0, maxY=65, yTicks=list(range(0, 61, 10)), height=460, referenceLines=ref, regions=regions,
                        xTicks=ticks([1990, 2000, 2010, 2020, 2025, 2030, 2035]),
                        note='Deuda bruta del Gobierno Central, % del PIB. Efectivos hasta 2025; 2026 es proyección del IFP. Shocks propios desde 2027; extensión propia desde 2031. El 45% se muestra como referencia actual, no como regla vigente durante toda la historia.')
    datasets.insert(1, dict(id='forecast', label='Detalle de escenarios · 2025–2035',
                           series=forecast_series, referenceLines=ref, regions=regions,
                           xTicks=ticks(range(2025, 2036)), yDigits=1, note=trajectories['note']))
    base = debt[debt.escenario.eq('Base compatible con la meta')]
    primary = []
    for col, label, color in [('balance_primario', 'Balance primario base', colors[0]),
                             ('balance_primario_estabilizador', 'Balance que estabiliza la deuda', colors[5])]:
        primary.append({'name': label, 'color': color,
                        'values': [point(r.anio, getattr(r, col)) for r in base.itertuples()]})
    datasets.append(dict(id='primary', label='¿Qué balance estabiliza la deuda?', series=primary,
                         yDigits=2, zeroLine=True, xTicks=ticks(range(2027, 2036)),
                         note='Porcentaje del PIB. Si el balance primario base queda por debajo del estabilizador, la deuda/PIB aumenta ese año. El estabilizador incluye ajustes stock-flujo y conciliación; es una identidad condicional, no una recomendación fiscal.'))
    for dataset in datasets:
        dataset['exactDates'] = True
        if dataset['id'] == 'decomposition':
            dataset['xTicks'] = ticks(range(2027, 2036))
            dataset['note'] += ' Los ajustes stock-flujo incluyen una conciliación calibrada a la senda oficial; no son una estimación causal.'

    # Thumbnail and full-size static fallback use the very same series as the web.
    fig, ax = plt.subplots(figsize=(12, 6.75), facecolor='white')
    ax.set_facecolor('white')
    for region in regions:
        ax.axvspan(int(region['start'][:4]), int(region['end'][:4]), color=region['color'])
    for series in trajectories['series']:
        ax.plot([int(p['date'][:4]) for p in series['values']], [p['value'] for p in series['values']],
                color=series['color'], linewidth=2.5, linestyle='--' if series.get('dash') else '-')
    ax.axhline(45, color=colors[5], linestyle='--', linewidth=2)
    ax.text(1991, 46.5, 'Nivel prudente: 45% del PIB', color=colors[5], fontsize=12)
    ax.set(xlim=(1990, 2035), ylim=(0, 65), ylabel='% del PIB', title='Deuda pública de Chile · historia y escenarios')
    ax.set_xticks([1990, 2000, 2010, 2020, 2025, 2030, 2035])
    ax.grid(axis='y', alpha=.2)
    fig.text(.12, .02, 'Efectivos hasta 2025 · Proyección 2026 · Escenarios desde 2027 · Extensión propia desde 2031', fontsize=10)
    fig.tight_layout(rect=(0, .045, 1, 1))
    out = ROOT / 'site/assets/img/charts'
    fig.savefig(out / 'debt_trajectories.png', dpi=140)
    with plt.rc_context({'svg.hashsalt': 'debt-history-v1'}):
        fig.savefig(out / 'debt_trajectories.svg', metadata={'Date': None})
    svg = out / 'debt_trajectories.svg'
    svg.write_text('\n'.join(line.rstrip() for line in svg.read_text().splitlines()) + '\n')
    fig.savefig(ROOT / 'site/assets/img/projects/debt.jpg', dpi=110)
    plt.close(fig)
