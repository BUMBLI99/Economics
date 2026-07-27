<div class="kpi-grid">
  <div class="kpi"><div class="kpi-label">Muestra</div><div class="kpi-value">2002–2026</div><div class="kpi-note">frecuencia mensual</div></div>
  <div class="kpi"><div class="kpi-label">Productos</div><div class="kpi-value">10</div><div class="kpi-note">tasas activas y pasivas</div></div>
  <div class="kpi"><div class="kpi-label">Comercial a 6 meses</div><div class="kpi-value">{{ transmission.commercial_6m }}</div><div class="kpi-note">pass-through acumulado</div></div>
  <div class="kpi"><div class="kpi-label">Vivienda UF a 6 meses</div><div class="kpi-value">{{ transmission.housing_6m }}</div><div class="kpi-note">respuesta muy acotada</div></div>
</div>

<div class="callout">
  <strong>Interpretación prudente.</strong> Los resultados describen un pass-through condicional con datos agregados. No identifican por sí solos un shock monetario exógeno ni separan completamente cambios en riesgo, composición de clientes, fondeo o competencia bancaria.
</div>

## Pregunta de investigación

¿Qué tan rápido y con qué intensidad se transmiten los cambios de la **Tasa de Política Monetaria** hacia tasas de captación y colocación en Chile? ¿Existen diferencias entre productos y entre episodios de alzas y bajas?

El proyecto combina tres ejercicios complementarios:

1. Modelos de rezagos distribuidos para el pass-through acumulado.
2. Especificaciones asimétricas para alzas y bajas de TPM.
3. Local projections para describir la trayectoria horizonte por horizonte.

## Canales principales

<figure class="chart-figure">
  <a href="../assets/img/charts/transmission_key_rates.svg" target="_blank"><img src="../assets/img/charts/transmission_key_rates.svg" alt="TPM y tasas bancarias clave en Chile"></a>
  <figcaption class="chart-caption">Las tasas comerciales responden más rápido; vivienda y captaciones muestran dinámicas distintas por plazo y unidad de denominación.</figcaption>
</figure>

## Pass-through acumulado

<div class="equation"><span class="equation-label">Rezagos distribuidos</span>Δr<sub>j,t</sub> = α<sub>j</sub> + Σ<sup>K</sup><sub>k=0</sub>β<sub>j,k</sub>ΔTPM<sub>t−k</sub> + ρ<sub>j</sub>Δr<sub>j,t−1</sub> + Γ<sub>j</sub>X<sub>t</sub> + μ<sub>m</sub> + ε<sub>j,t</sub></div>

<figure class="chart-figure">
  <a href="../assets/img/charts/transmission_cumulative.svg" target="_blank"><img src="../assets/img/charts/transmission_cumulative.svg" alt="Pass-through acumulado de la TPM por producto"></a>
  <figcaption class="chart-caption">La línea de referencia en 1 corresponde a un traspaso acumulado uno a uno.</figcaption>
</figure>

A seis meses, el coeficiente acumulado es cercano a **{{ transmission.commercial_6m }}** para crédito comercial total y **{{ transmission.consumption_6m }}** para consumo total. En vivienda UF, el coeficiente es prácticamente nulo en esta especificación mensual, consistente con una dinámica más lenta y con la influencia de tasas largas reales.

{{ transmission.summary_table|safe }}

## Asimetría entre alzas y bajas

<figure class="chart-figure">
  <a href="../assets/img/charts/transmission_asymmetry.svg" target="_blank"><img src="../assets/img/charts/transmission_asymmetry.svg" alt="Pass-through asimétrico para alzas y bajas de TPM"></a>
  <figcaption class="chart-caption">En varios productos el traspaso estimado es mayor durante bajas de TPM, especialmente en consumo; la comparación es descriptiva y sensible a la muestra.</figcaption>
</figure>

La asimetría puede reflejar competencia, costos de ajuste, composición de cartera, riesgo o diferencias entre ciclos monetarios. No debe atribuirse mecánicamente a una conducta particular de la banca sin un diseño adicional.

## Local projections

<figure class="chart-figure">
  <a href="../assets/img/charts/transmission_local_projections.svg" target="_blank"><img src="../assets/img/charts/transmission_local_projections.svg" alt="Local projections del pass-through de la TPM"></a>
  <figcaption class="chart-caption">Trayectorias de respuesta con intervalos de confianza del 95%.</figcaption>
</figure>

Las local projections permiten verificar si la forma dinámica obtenida con rezagos distribuidos se mantiene sin imponer la misma estructura paramétrica en todos los horizontes.

## Robustez y cautelas

- Se comparan muestra completa, período posterior a 2010 y muestra excluyendo 2020–2023.
- Las tasas promedio pueden cambiar por composición de operaciones, no solo por precio puro.
- La TPM y las tasas responden simultáneamente al ciclo macroeconómico; los controles reducen, pero no eliminan, endogeneidad.
- El canal hipotecario requiere incorporar con mayor detalle tasas largas reales, spreads y condiciones de oferta.
- Los coeficientes mayores que uno no implican automáticamente sobre-reacción causal: pueden capturar movimientos conjuntos de riesgo y ciclo.

## Archivos principales

<div class="download-grid">
  <a class="download" href="../assets/files/transmission-pass-through-summary.csv"><div><strong>Resumen de pass-through</strong><span>CSV · coeficientes por producto</span></div><span>↓</span></a>
  <a class="download" href="../assets/files/transmission-local-projections.csv"><div><strong>Local projections</strong><span>CSV · estimaciones e intervalos</span></div><span>↓</span></a>
</div>
