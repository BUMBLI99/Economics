<div class="callout"><strong>Pregunta central.</strong> ¿Qué combinación de crecimiento nominal, costo efectivo de la deuda, balance primario y ajustes stock-flujo mantiene la deuda bruta bajo el nivel prudente de 45% del PIB?</div>

<div class="kpi-grid">
  <div class="kpi"><div class="kpi-label">Senda compatible · 2030</div><div class="kpi-value">{{ debt.base_2030 }}%</div><div class="kpi-note">deuda bruta del Gobierno Central</div></div>
  <div class="kpi"><div class="kpi-label">Gasto comprometido · 2030</div><div class="kpi-value">{{ debt.committed_2030 }}%</div><div class="kpi-note">supera el nivel prudente</div></div>
  <div class="kpi"><div class="kpi-label">Margen base · 2030</div><div class="kpi-value">{{ debt.base_margin }} pp</div><div class="kpi-note">respecto de 45% del PIB</div></div>
</div>

## Resultado principal

La trayectoria compatible con la meta llega a **{{ debt.base_2030 }}% del PIB en 2030**, mientras la senda asociada al gasto comprometido alcanza **{{ debt.committed_2030 }}%**. La diferencia no es una previsión independiente: organiza las dos trayectorias del IFP 2T 2026 dentro de una identidad común y hace visibles sus supuestos.

<div class="callout callout-critical"><strong>Lectura correcta.</strong> El 45% es el nivel prudente utilizado por la regla fiscal dual, no un techo legal que active automáticamente una crisis. Los escenarios son condicionales y no tienen probabilidades asignadas.</div>

## Escenarios interactivos

<div class="interactive-card" data-project-chart="debt" data-url="../assets/data/project_charts.json">
  <div class="chart-controls">
    <label>Vista<select data-dataset-select></select></label>
    <label>Horizonte<select data-range-select><option value="0">Completo</option></select></label>
  </div>
  <div class="chart-legend" data-chart-legend></div>
  <div class="interactive-chart" data-generic-chart></div>
  <p class="chart-note" data-chart-note></p>
  <div data-chart-table hidden></div>
</div>

El escenario de mayor tasa incluido en el archivo original es una sensibilidad mecánica. Para una lectura más realista, el simulador siguiente transmite gradualmente un shock de mercado al costo promedio del stock conforme se refinancia la deuda.

## Simulador de política fiscal

<div class="debt-simulator" data-debt-simulator data-url="../assets/data/debt_simulator.json">
  <div class="simulator-controls">
    <label>Crecimiento nominal<select data-debt-growth><option value="0">Base</option><option value="-1">−1,0 pp</option><option value="-2">−2,0 pp</option><option value="1">+1,0 pp</option></select></label>
    <label>Tasa de mercado<select data-debt-rate><option value="0">Base</option><option value="1">+1,0 pp</option><option value="2">+2,0 pp</option><option value="3">+3,0 pp</option></select></label>
    <label>Balance primario<select data-debt-primary><option value="0">Base</option><option value="-0.5">−0,5 pp</option><option value="-1">−1,0 pp</option><option value="0.5">+0,5 pp</option></select></label>
    <label>Ajuste stock-flujo<select data-debt-sfa><option value="0">Base</option><option value="0.25">+0,25 pp</option><option value="0.5">+0,50 pp</option></select></label>
  </div>
  <div class="kpi-grid simulator-output">
    <div class="kpi"><div class="kpi-label">Deuda simulada · 2030</div><div class="kpi-value" data-debt-2030>—</div></div>
    <div class="kpi"><div class="kpi-label">Máximo del horizonte</div><div class="kpi-value" data-debt-max>—</div></div>
    <div class="kpi"><div class="kpi-label">Primer año sobre 45%</div><div class="kpi-value" data-debt-cross>—</div></div>
  </div>
  <div class="interactive-chart" data-debt-chart></div>
  <p class="chart-note">Supuesto de traspaso: 25% del shock de tasa de mercado se incorpora al costo efectivo cada año. El resultado es ilustrativo.</p>
</div>

## Método y trazabilidad

La dinámica se expresa como:

<div class="equation"><span class="equation-label">Identidad de deuda</span>d<sub>t</sub> = [(1+i<sub>t</sub>)/(1+g<sub>t</sub>)] d<sub>t−1</sub> − pb<sub>t</sub> + sfa<sub>t</sub></div>

- **Crecimiento nominal:** se obtiene del PIB nominal publicado, evitando aproximarlo como PIB real más IPC.
- **Tasa efectiva:** intereses sobre el stock inicial. En sensibilidades de mercado, el shock se incorpora gradualmente.
- **Balance primario:** positivo cuando existe superávit.
- **Ajuste stock-flujo:** separa operaciones financieras netas, valorización y una conciliación explícita de la senda compatible.
- **Horizonte:** datos efectivos hasta 2025, marco oficial hasta 2030 y extensión propia —claramente diferenciada— entre 2031 y 2035.

{{ debt.summary_table|safe }}

## Qué mejora respecto del prototipo

- Se separan datos, cuentas fiscales, motor de proyección y publicación web.
- La identidad de necesidades de financiamiento detiene el pipeline si usos y fuentes no cierran.
- El shock de tasa distingue costo marginal de financiamiento y costo efectivo del stock.
- La página distingue resultados oficiales, calibraciones necesarias y supuestos propios.
- Los resultados pueden inspeccionarse con tooltip y descargarse en formatos reutilizables.

## Límites

- Es una DSA de deuda bruta, no un balance soberano neto de activos.
- No modela por instrumento la moneda, UF, vencimiento ni cobertura; el traspaso de 25% es configurable, no una estimación estructural.
- La valorización residual puede agrupar efectos heterogéneos que las tablas públicas no identifican por separado.
- No incorpora pasivos contingentes, empresas públicas ni una función de reacción fiscal estimada.
- La extensión 2031–2035 no pertenece a Dipres, Hacienda ni al CFA.

## Descargas

<div class="download-grid">
  <a class="download" href="../assets/files/debt-summary.csv"><div><strong>Resumen de escenarios</strong><span>CSV · principales resultados</span></div><span>↓</span></a>
  <a class="download" href="../assets/files/debt-scenarios.csv"><div><strong>Trayectorias completas</strong><span>CSV · supuestos y descomposición</span></div><span>↓</span></a>
  <a class="download" href="../assets/files/debt-sensitivity.csv"><div><strong>Matriz de sensibilidad</strong><span>CSV · crecimiento y balance</span></div><span>↓</span></a>
</div>

## Fuentes

- Dirección de Presupuestos, *Informe de Finanzas Públicas, segundo trimestre de 2026* y anexos Excel.
- Ministerio de Hacienda, Oficina de la Deuda Pública.
- Consejo Fiscal Autónomo, estadísticas de deuda bruta y nivel prudente.
