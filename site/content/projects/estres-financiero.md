<div class="kpi-grid">
  <div class="kpi"><div class="kpi-label">Última observación</div><div class="kpi-value">{{ stress.date }}</div><div class="kpi-note">datos diarios</div></div>
  <div class="kpi"><div class="kpi-label">Índice 30 días</div><div class="kpi-value">{{ stress.index_30d }}</div><div class="kpi-note">z-score agregado</div></div>
  <div class="kpi"><div class="kpi-label">Componente FX</div><div class="kpi-value">{{ stress.fx_30d }}</div><div class="kpi-note">media móvil 30 días</div></div>
  <div class="kpi"><div class="kpi-label">Régimen</div><div class="kpi-value">{{ stress.regime }}</div><div class="kpi-note">clasificación descriptiva</div></div>
</div>

<div class="callout">
  <strong>Lectura vigente.</strong> Al {{ stress.date }}, el índice se ubica en {{ stress.index_30d }}, compatible con <strong>{{ stress.regime|lower }}</strong>. Tanto el componente cambiario como el de tasa larga están por debajo de sus valores explicados por la distribución histórica del modelo.
</div>

## Qué mide el índice

El objetivo es separar dos dimensiones que suelen mezclarse en la discusión de mercado:

- Movimientos del USD/CLP y de la tasa soberana 10Y que pueden asociarse a factores globales observables.
- Desvíos específicos de Chile respecto de esos fundamentos.

El índice combina los residuos estandarizados de ambos mercados. Un valor positivo indica presión superior a la predicha por el modelo; uno negativo indica condiciones más benignas que la referencia histórica condicional.

## Resultado principal

<figure class="chart-figure">
  <a href="../assets/img/charts/stress_index_chile.svg" target="_blank"><img src="../assets/img/charts/stress_index_chile.svg" alt="Índice de estrés financiero de mercado para Chile"></a>
  <figcaption class="chart-caption">La media móvil de 30 días reduce el ruido diario y facilita la identificación de episodios persistentes.</figcaption>
</figure>

<figure class="chart-figure">
  <a href="../assets/img/charts/stress_components_chile.svg" target="_blank"><img src="../assets/img/charts/stress_components_chile.svg" alt="Componentes cambiario y de tasa 10Y del índice de estrés"></a>
  <figcaption class="chart-caption">El índice agregado puede esconder episodios dominados por un solo mercado; por eso se publican ambos componentes.</figcaption>
</figure>

## Modelos de primera etapa

<div class="equation"><span class="equation-label">Tipo de cambio</span>ln(USDCLP<sub>t</sub>) = α + β′Factores globales<sub>t</sub> + γ′Fundamentos relativos<sub>t</sub> + ε<sup>FX</sup><sub>t</sub></div>

<div class="equation"><span class="equation-label">Tasa soberana 10Y</span>10Y<sub>CLP,t</sub> = α + δ·10Y<sub>UST,t</sub> + θ′Factores globales<sub>t</sub> + ε<sup>10Y</sup><sub>t</sub></div>

El bloque cambiario utiliza tendencia, IPC relativo Chile–Estados Unidos, cobre, petróleo, VIX, índice amplio del dólar, CNY y mercados accionarios. El bloque de tasa larga incorpora Treasury 10Y, VIX, dólar global, CNY y acciones.

<figure class="chart-figure">
  <a href="../assets/img/charts/stress_fx_fit.svg" target="_blank"><img src="../assets/img/charts/stress_fx_fit.svg" alt="USD CLP efectivo y ajustado por el modelo"></a>
  <figcaption class="chart-caption">El residuo no es el nivel del tipo de cambio, sino su distancia respecto del valor ajustado por los factores incluidos.</figcaption>
</figure>

<figure class="chart-figure">
  <a href="../assets/img/charts/stress_y10_fit.svg" target="_blank"><img src="../assets/img/charts/stress_y10_fit.svg" alt="Tasa soberana 10Y efectiva y ajustada por el modelo"></a>
  <figcaption class="chart-caption">La primera etapa explica una fracción importante, pero no toda, de la variación diaria de la tasa soberana.</figcaption>
</figure>

## Construcción del indicador

<div class="equation"><span class="equation-label">Normalización</span>z<sup>m</sup><sub>t</sub> = ε<sup>m</sup><sub>t</sub> / σ(ε<sup>m</sup>) &nbsp;&nbsp;&nbsp; m ∈ {FX, 10Y}</div>

<div class="equation"><span class="equation-label">Índice agregado</span>Stress<sub>t</sub> = ½(z<sup>FX</sup><sub>t</sub> + z<sup>10Y</sup><sub>t</sub>)</div>

La clasificación de régimen utiliza umbrales simples sobre la media móvil de 30 días. Es una herramienta de monitoreo, no una probabilidad de crisis.

## Diagnóstico de ajuste

{{ stress.diagnostics_table|safe }}

El alto R² del modelo cambiario refleja una fuerte comovilidad con factores globales y tendencias en la muestra. No significa que el tipo de cambio esté “determinado” por el modelo ni que el residuo sea exclusivamente riesgo local.

## Límites de interpretación

- Los residuos dependen de la especificación y de la ventana muestral.
- Un factor local omitido puede aparecer como estrés aunque no represente deterioro financiero amplio.
- Los z-scores no son comparables de manera mecánica entre modelos con volatilidades residuales distintas.
- El indicador no incorpora crédito, acciones locales, spreads corporativos ni liquidez.
- Los umbrales de régimen son descriptivos y no están calibrados a eventos de crisis oficiales.

## Archivos principales

<div class="download-grid">
  <a class="download" href="../assets/files/stress-latest-snapshot.csv"><div><strong>Último snapshot</strong><span>CSV · componentes e índice</span></div><span>↓</span></a>
  <a class="download" href="../assets/files/stress-episodes.csv"><div><strong>Episodios destacados</strong><span>CSV · fechas y regímenes</span></div><span>↓</span></a>
</div>
