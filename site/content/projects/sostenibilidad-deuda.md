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

La vista inicial reúne la historia efectiva desde 1990 y los escenarios hasta 2035. El selector permite ampliar el período de proyección, descomponer el cambio anual de la deuda y comparar el balance primario con el que estabilizaría la razón deuda/PIB. La línea de 45% representa el nivel prudente actual: no implica que esta referencia rigiera durante toda la historia.

Los escenarios de riesgo y el simulador parten de la proyección de deuda de cierre de 2026 y aplican shocks permanentes desde 2027. El shock de tasas se transmite gradualmente al costo efectivo: cada año se incorpora el 25% de la diferencia pendiente respecto del shock total. Es una aproximación al refinanciamiento, no una estimación de la estructura de vencimientos.

## Simulador de política fiscal

Los escenarios predefinidos usan shocks distintos: menor crecimiento (−1 pp), mayor tasa de mercado (+1,5 pp), menor balance primario (−0,3 pp del PIB) y combinación adversa (−1 pp de crecimiento, +1,5 pp de tasa, −0,5 pp de balance y +0,25 pp de ajustes stock-flujo). La combinación adversa no es la suma exacta de los tres escenarios individuales, porque supone un deterioro primario mayor y añade un ajuste stock-flujo.

<div class="debt-simulator" data-debt-simulator data-url="../assets/data/debt_simulator.json">
  <div class="simulator-controls">
    <label>Crecimiento nominal<select data-debt-growth><option value="0">Base</option><option value="-1">−1,0 pp</option><option value="-2">−2,0 pp</option><option value="1">+1,0 pp</option></select></label>
    <label>Tasa de mercado<select data-debt-rate><option value="0">Base</option><option value="1">+1,0 pp</option><option value="1.5">+1,5 pp</option><option value="2">+2,0 pp</option><option value="3">+3,0 pp</option></select></label>
    <label>Balance primario<select data-debt-primary><option value="0">Base</option><option value="-0.3">−0,3 pp</option><option value="-0.5">−0,5 pp</option><option value="-1">−1,0 pp</option><option value="0.5">+0,5 pp</option></select></label>
    <label>Ajuste stock-flujo<select data-debt-sfa><option value="0">Base</option><option value="0.25">+0,25 pp</option><option value="0.5">+0,50 pp</option></select></label>
  </div>
  <div class="kpi-grid simulator-output">
    <div class="kpi"><div class="kpi-label">Deuda simulada · 2030</div><div class="kpi-value" data-debt-2030>—</div></div>
    <div class="kpi"><div class="kpi-label">Máximo del horizonte</div><div class="kpi-value" data-debt-max>—</div></div>
    <div class="kpi"><div class="kpi-label">Primer año sobre 45%</div><div class="kpi-value" data-debt-cross>—</div></div>
  </div>
  <div class="interactive-chart" data-debt-chart></div>
  <p class="chart-note">Shocks desde 2027. Traspaso de tasas: 25% de la diferencia pendiente por año (25% el primero, 43,75% acumulado el segundo). El resultado es ilustrativo.</p>
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

## Qué analiza el ejercicio

El proyecto transforma las proyecciones fiscales en un análisis de sostenibilidad de deuda: parte del stock de deuda observado y reconstruye su evolución anual a partir del crecimiento nominal, el costo efectivo de los intereses, el balance primario y los ajustes stock-flujo. Así, la deuda deja de ser solamente un resultado final y puede identificarse cuánto aporta cada componente a su aumento o disminución.

El contraste central enfrenta dos trayectorias publicadas en el IFP 2T 2026. La primera corresponde a una senda de balances compatible con la meta fiscal; la segunda mantiene el gasto ya comprometido. Su distancia mide la diferencia de deuda acumulada entre ambas sendas, no el ajuste fiscal anual mínimo necesario para permanecer bajo 45%. El ejercicio tampoco interpreta ese nivel prudente como una predicción de crisis.

Para 2031–2035 se extiende el ejercicio con supuestos propios y explícitos. Ese horizonte permite estudiar la persistencia de los desequilibrios: un desvío pequeño puede parecer acotado en 2030, pero acumularse cuando el crecimiento permanece bajo, el refinanciamiento encarece gradualmente el stock de deuda o el balance primario tarda en corregirse.

Los escenarios y el simulador responden cuatro preguntas concretas:

- ¿Qué ocurre con la deuda si el crecimiento nominal resulta menor al previsto?
- ¿Con qué velocidad un aumento de las tasas de mercado se transmite al costo efectivo del stock?
- ¿Cuánto cambia la trayectoria si el esfuerzo fiscal es menor o aparecen ajustes stock-flujo adicionales?
- ¿En qué año se cruza el nivel prudente cuando estos riesgos actúan por separado o en conjunto?

La herramienta permite modificar esos supuestos, comparar la trayectoria resultante con el escenario base y descargar las series utilizadas. Los resultados son ejercicios condicionales: muestran la mecánica y magnitud de los riesgos, no la probabilidad de que cada escenario ocurra.

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

- Dirección de Presupuestos, [*Informe de Finanzas Públicas, segundo trimestre de 2026*](https://www.dipres.gob.cl/598/articles-419241_Informe_PDF.pdf?ts=1786041894), capítulo II, y anexos Excel. Corte del ejercicio: 29 de julio de 2026; no representa una actualización diaria.
- Ministerio de Hacienda, Oficina de la Deuda Pública.
- Consejo Fiscal Autónomo, estadísticas de deuda bruta y nivel prudente.
