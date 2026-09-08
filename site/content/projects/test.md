<div class="kpi-grid">
  <div class="kpi"><div class="kpi-label">Países</div><div class="kpi-value">5</div><div class="kpi-note">CLP, BRL, MXN, PEN y COP</div></div>
  <div class="kpi"><div class="kpi-label">Frecuencia</div><div class="kpi-value">Diaria</div><div class="kpi-note">muestra común desde 2012</div></div>
  <div class="kpi"><div class="kpi-label">Chile · residuo FX</div><div class="kpi-value">{{ exchange.clp_fx }}</div><div class="kpi-note">z-score al {{ exchange.date }}</div></div>
  <div class="kpi"><div class="kpi-label">Chile · residuo 10Y</div><div class="kpi-value">{{ exchange.clp_y10 }}</div><div class="kpi-note">z-score al {{ exchange.date }}</div></div>
</div>

<div class="callout">
  <strong>Objetivo.</strong> El proyecto no busca un “valor justo” único. Construye una referencia condicional común para comparar cuándo el tipo de cambio o la tasa soberana de un país se separan de factores externos observables y de su propia historia residual.
</div>

## Estructura del modelo

La primera etapa se estima por país y mercado. Para el tipo de cambio se combinan inflación relativa, materias primas, volatilidad global, dólar amplio, CNY y mercados accionarios. Para tasas 10Y se incorporan Treasury, VIX, dólar global, factores regionales y riesgo soberano EMBIG.

<div class="equation"><span class="equation-label">Primera etapa FX</span>ln(FX<sub>i,t</sub>) = α<sub>i</sub> + β<sub>i</sub>′G<sub>t</sub> + γ<sub>i</sub>′F<sub>i,t</sub> + ε<sup>FX</sup><sub>i,t</sub></div>

<div class="equation"><span class="equation-label">Primera etapa 10Y</span>10Y<sub>i,t</sub> = a<sub>i</sub> + δ<sub>i</sub>UST10<sub>t</sub> + θ<sub>i</sub>′G<sub>t</sub> + λ<sub>i</sub>EMBIG<sub>i,t</sub> + ε<sup>10Y</sup><sub>i,t</sub></div>

<div class="equation"><span class="equation-label">Segunda etapa</span>z(ε<sup>FX</sup><sub>i,t</sub>) = c<sub>i</sub> + ϕ<sub>i</sub>Spread10Y<sub>i,t</sub> + u<sub>i,t</sub></div>

La normalización permite comparar mercados expresados en unidades distintas. Un z-score positivo indica una presión por sobre la referencia del modelo; no equivale automáticamente a desalineamiento estructural.

## Resultados regionales

<figure class="chart-figure">
  <a href="../assets/img/charts/exchange_fx_residuals.svg" target="_blank"><img src="../assets/img/charts/exchange_fx_residuals.svg" alt="Residuos cambiarios normalizados para cinco países de América Latina"></a>
  <figcaption class="chart-caption">Los episodios regionales pueden ser sincronizados, pero la intensidad y persistencia varían por moneda.</figcaption>
</figure>

<figure class="chart-figure">
  <a href="../assets/img/charts/exchange_y10_residuals.svg" target="_blank"><img src="../assets/img/charts/exchange_y10_residuals.svg" alt="Residuos de tasas soberanas 10Y para cinco países de América Latina"></a>
  <figcaption class="chart-caption">La comparación usa una muestra alineada para evitar colas de datos sin contraparte en FX.</figcaption>
</figure>

## Selector por país

<div class="interactive-card" data-exchange-dashboard data-url="../assets/data/exchange_dashboard.json">
  <div class="chart-controls">
    <label for="country-select">País</label>
    <select id="country-select" data-country-select>
      <option value="CLP">Chile · CLP</option>
      <option value="BRL">Brasil · BRL</option>
      <option value="MXN">México · MXN</option>
      <option value="PEN">Perú · PEN</option>
      <option value="COP">Colombia · COP</option>
    </select>
  </div>
  <h3>Tasas observadas</h3>
  <div class="interactive-chart" data-rates-chart aria-live="polite"></div>
  <div class="chart-legend"><span class="legend-item"><span class="legend-swatch" style="background:#193044"></span>TPM</span><span class="legend-item"><span class="legend-swatch" style="background:#2b7777"></span>Tasa 10Y</span></div>
  <h3>Desvío cambiario del modelo</h3>
  <div class="interactive-chart" data-residuals-chart aria-live="polite"></div>
  <div class="chart-legend"><span class="legend-item"><span class="legend-swatch" style="background:#b4573d"></span>Residuo FX estandarizado</span></div>
</div>

## Ajuste de primera etapa

<figure class="chart-figure">
  <a href="../assets/img/charts/exchange_model_fit.svg" target="_blank"><img src="../assets/img/charts/exchange_model_fit.svg" alt="R cuadrado de los modelos FX y 10Y por país"></a>
  <figcaption class="chart-caption">El ajuste es mayor en FX y heterogéneo en tasas 10Y. El R² es una métrica dentro de muestra, no una prueba de causalidad.</figcaption>
</figure>

{{ exchange.fit_table|safe }}

## Riesgo soberano y presión cambiaria

<figure class="chart-figure">
  <a href="../assets/img/charts/exchange_second_stage.svg" target="_blank"><img src="../assets/img/charts/exchange_second_stage.svg" alt="Coeficientes de segunda etapa entre spread soberano y residuo cambiario"></a>
  <figcaption class="chart-caption">La relación estimada es positiva en los cinco países; Perú y Chile presentan coeficientes mayores en esta especificación.</figcaption>
</figure>

La segunda etapa documenta una asociación entre mayor tensión soberana y una depreciación superior a la explicada por factores globales. No debe interpretarse como causalidad unidireccional: ambos mercados pueden responder a noticias locales comunes.

## Límites de interpretación

- La especificación diaria privilegia seguimiento y comparabilidad, no identificación estructural completa.
- Los resultados dependen de las fuentes y de la disponibilidad simultánea de series.
- El residuo mezcla riesgo local, liquidez, noticias y cualquier factor omitido.
- Comparar z-scores ayuda a leer intensidad relativa, pero no convierte todos los mercados en equivalentes.
- El último snapshot puede no incluir todos los países el mismo día si una fuente presenta rezago.

## Reportes y salidas

<div class="download-grid">
  <a class="download" href="../assets/files/exchange_model_report.pdf"><div><strong>Reporte del modelo</strong><span>PDF · especificación y resultados</span></div><span>↓</span></a>
  <a class="download" href="../assets/files/exchange_model_outputs_2025.xlsx"><div><strong>Salidas consolidadas</strong><span>XLSX · tablas y series</span></div><span>↓</span></a>
</div>
