<div class="kpi-grid">
  <div class="kpi"><div class="kpi-label">Último mes</div><div class="kpi-value">{{ yield_curve.date }}</div><div class="kpi-note">promedios mensuales</div></div>
  <div class="kpi"><div class="kpi-label">BCP 10 años</div><div class="kpi-value">{{ yield_curve.bcp10 }}%</div><div class="kpi-note">tasa nominal</div></div>
  <div class="kpi"><div class="kpi-label">Pendiente 10Y–2Y</div><div class="kpi-value">{{ yield_curve.slope }} pp</div><div class="kpi-note">curva nominal</div></div>
  <div class="kpi"><div class="kpi-label">Compensación 10Y</div><div class="kpi-value">{{ yield_curve.be10 }} pp</div><div class="kpi-note">BCP 10Y menos BCU 10Y</div></div>
</div>

<div class="callout">
  <strong>Mejora sustantiva.</strong> La versión anterior era un prototipo con datos simulados. Esta página utiliza tasas efectivas BCP y BCU procesadas desde el Banco Central de Chile; ya no presenta una simulación como evidencia empírica.
</div>

## Qué permite estudiar la curva

La estructura temporal de tasas resume información sobre la trayectoria esperada de la política monetaria, primas por plazo, inflación, riesgo y liquidez. El monitor publica tres lecturas complementarias:

- Nivel de la curva nominal y real.
- Pendiente 10Y–2Y de la curva nominal.
- Compensación inflacionaria aproximada a 5 y 10 años.

## Curva vigente

<figure class="chart-figure">
  <a href="../assets/img/charts/yield_curve_latest.svg" target="_blank"><img src="../assets/img/charts/yield_curve_latest.svg" alt="Curva soberana chilena nominal y real vigente"></a>
  <figcaption class="chart-caption">La curva nominal utiliza BCP a 2, 5 y 10 años; la real utiliza BCU a 5 y 10 años.</figcaption>
</figure>

## Explorador histórico

<div class="interactive-card" data-yield-curve data-url="../assets/data/yield_curve.json">
  <div class="chart-controls">
    <label for="curve-slider">Fecha: <strong data-curve-date></strong></label>
    <input id="curve-slider" data-curve-slider type="range" min="0" value="0" step="1" style="flex:1;min-width:220px">
  </div>
  <div class="interactive-chart" data-curve-chart aria-live="polite"></div>
  <div class="chart-legend"><span class="legend-item"><span class="legend-swatch" style="background:#193044"></span>BCP nominal</span><span class="legend-item"><span class="legend-swatch" style="background:#2b7777"></span>BCU real</span></div>
</div>

## Pendiente de la curva

<div class="equation"><span class="equation-label">Pendiente nominal</span>Slope<sub>t</sub> = BCP10Y<sub>t</sub> − BCP2Y<sub>t</sub></div>

<figure class="chart-figure">
  <a href="../assets/img/charts/yield_curve_slope.svg" target="_blank"><img src="../assets/img/charts/yield_curve_slope.svg" alt="Pendiente BCP 10 años menos BCP 2 años"></a>
  <figcaption class="chart-caption">Una pendiente negativa identifica inversión de curva, pero no constituye por sí sola una señal mecánica de recesión.</figcaption>
</figure>

La pendiente combina expectativas de política, primas por plazo y cambios en oferta y demanda de instrumentos. Por ello su lectura debe complementarse con actividad, inflación y condiciones externas.

## Compensación inflacionaria

<div class="equation"><span class="equation-label">Aproximación</span>Compensación<sub>h,t</sub> ≈ BCP<sub>h,t</sub> − BCU<sub>h,t</sub></div>

<figure class="chart-figure">
  <a href="../assets/img/charts/yield_curve_breakeven.svg" target="_blank"><img src="../assets/img/charts/yield_curve_breakeven.svg" alt="Compensación inflacionaria aproximada a 5 y 10 años"></a>
  <figcaption class="chart-caption">La diferencia nominal-real incorpora expectativas de inflación, pero también primas de riesgo inflacionario y liquidez.</figcaption>
</figure>

## Datos y construcción

Las series provienen del panel mensual de tasas utilizado en el proyecto de transmisión de la TPM. Se calculan promedios mensuales y se conservan únicamente fechas con información simultánea para las curvas mostradas.

No se interpola una curva continua ni se estima una función Nelson–Siegel. La visualización conecta nodos observados para mantener transparente el contenido informativo de los datos.

## Límites de interpretación

- BCP y BCU no son instrumentos idénticos en liquidez y composición de tenedores.
- La compensación inflacionaria no es una expectativa pura.
- La pendiente depende de primas por plazo y no solo de expectativas de TPM.
- Los promedios mensuales suavizan movimientos intradía y episodios breves.
- La ausencia de nodos de 1 y 3 años limita la forma observable de la curva.

## Archivo de datos

<div class="download-grid">
  <a class="download" href="../assets/files/yield-curve-monthly.csv"><div><strong>Panel mensual de curva</strong><span>CSV · BCP, BCU, pendiente y compensaciones</span></div><span>↓</span></a>
</div>
