<div class="kpi-grid">
  <div class="kpi"><div class="kpi-label">Corte experimental</div><div class="kpi-value">{{ imacec.experimental.target }}</div><div class="kpi-note">M4 · Dinámico</div></div>
  <div class="kpi"><div class="kpi-label">Nowcast M4</div><div class="kpi-value">{{ imacec.experimental.forecast }}{% if imacec.ready %}%{% endif %}</div><div class="kpi-note">intervalo 80%: {{ imacec.experimental.lwr }} a {{ imacec.experimental.upr }}</div></div>
  <div class="kpi"><div class="kpi-label">Corte INE</div><div class="kpi-value">{{ imacec.ine.target }}</div><div class="kpi-note">M8P · INE + IVS real</div></div>
  <div class="kpi"><div class="kpi-label">Nowcast M8P</div><div class="kpi-value">{{ imacec.ine.forecast }}{% if imacec.ready %}%{% endif %}</div><div class="kpi-note">intervalo 80%: {{ imacec.ine.lwr }} a {{ imacec.ine.upr }}</div></div>
</div>

{% if not imacec.ready %}
<div class="callout callout-warning">
  <strong>Actualización metodológica lista.</strong> Se retiraron de la publicación las cifras producidas por las especificaciones antiguas. Los resultados M4/M8P aparecerán automáticamente después de la primera ejecución con credenciales BCCh e IVS oficial; no se han relabelado proyecciones heredadas.
</div>
{% endif %}

## Dos cortes, dos modelos fijos

El proyecto anticipa la variación interanual del **IMACEC total** sin mezclar conjuntos de información ni escoger retrospectivamente el modelo que mejor luce en cada actualización.

1. **Corte experimental — M4 Dinámico.** Se activa con ventas minoristas, monto y cantidad de operaciones de crédito del mes objetivo, el IMACEC rezagado y controles calendario.
2. **Corte INE — M8P parsimonioso.** Añade minería, manufactura, comercio, electricidad, avisos laborales rezagados y un factor real construido con seis Índices de Ventas de Servicios.

Los meses objetivo pueden diferir: cada corte publica el mes más reciente para el cual están disponibles **todos** los predictores exigidos por su propia fórmula. Si el IMACEC efectivo ya fue publicado, la salida se identifica como pseudo-nowcast y queda disponible para evaluación.

## Explorador interactivo

<div class="interactive-card" data-project-chart="imacec" data-url="../assets/data/project_charts.json">
  <div class="chart-controls"><label for="imacec-dataset">Corte informativo</label><select id="imacec-dataset" data-dataset-select></select></div>
  <div class="interactive-chart" data-generic-chart aria-live="polite"></div><div class="chart-legend" data-chart-legend></div>
</div>

El selector separa M4 y M8P. Cada gráfico muestra el IMACEC efectivo, el ajuste/nowcast del modelo correspondiente y la mediana de la EEE cuando existe para el mismo mes objetivo.

## Comparación correcta con la EEE

La Encuesta de Expectativas Económicas fechada en el mes **M** pregunta por el IMACEC de **un mes atrás**. Por eso el pipeline conserva dos fechas: el mes de publicación de la encuesta y el mes **M−1** al que corresponde su expectativa. La EEE nunca se desplaza hacia adelante para hacerla coincidir artificialmente con el nowcast.

{% if imacec.ready %}
| Corte | Mes IMACEC | Modelo | EEE comparable | Encuesta publicada |
|---|---|---|---:|---|
| Experimental | {{ imacec.experimental.target }} | {{ imacec.experimental.forecast }}% | {{ imacec.experimental.eee }}% | {{ imacec.experimental.eee_survey }} |
| INE | {{ imacec.ine.target }} | {{ imacec.ine.forecast }}% | {{ imacec.ine.eee }}% | {{ imacec.ine.eee_survey }} |
{% endif %}

<figure class="chart-figure">
  <a href="../assets/img/charts/imacec_m4_history.svg" target="_blank"><img src="../assets/img/charts/imacec_m4_history.svg" alt="IMACEC efectivo, M4 Dinámico y EEE alineada"></a>
  <figcaption class="chart-caption">Corte experimental. El punto más reciente se regenera al actualizar las estadísticas experimentales.</figcaption>
</figure>

<figure class="chart-figure">
  <a href="../assets/img/charts/imacec_m8p_history.svg" target="_blank"><img src="../assets/img/charts/imacec_m8p_history.svg" alt="IMACEC efectivo, M8P INE IVS real y EEE alineada"></a>
  <figcaption class="chart-caption">Corte INE. M8P solo se estima cuando los cuatro indicadores sectoriales y los seis IVS contemporáneos están completos.</figcaption>
</figure>

## Especificaciones publicadas

<div class="equation"><span class="equation-label">M4 · Dinámico</span>IMACEC<sub>t</sub> = f(ventas<sub>t</sub>, crédito monto<sub>t</sub>, crédito cantidad<sub>t</sub>, IMACEC<sub>t−1</sub>, calendario)</div>

<div class="equation"><span class="equation-label">M8P · INE + IVS real parsimonioso</span>IMACEC<sub>t</sub> = f(crédito cantidad<sub>t</sub>, IMACEC<sub>t−1</sub>, avisos<sub>t−1</sub>, sectores INE<sub>t</sub>, IVS real<sub>t</sub>, crédito real<sub>t</sub>, calendario)</div>

El factor IVS real es el promedio de seis variaciones interanuales de índices de ventas de servicios deflactados por el IPC de Servicios. Se exige cobertura completa; si falta una rama, M8P no publica ese mes.

## Evaluación pseudo out-of-sample

<figure class="chart-figure">
  <a href="../assets/img/charts/imacec_oos_rmse.svg" target="_blank"><img src="../assets/img/charts/imacec_oos_rmse.svg" alt="RMSE pseudo out-of-sample de M4 y M8P"></a>
  <figcaption class="chart-caption">Comparación recursiva de las dos especificaciones fijadas. Usa la base final reconstruida, no vintages históricos completos.</figcaption>
</figure>

{{ imacec.oos_table|safe }}

## Reproducibilidad y límites

- M4 y M8P están fijados en código; no existe selección dinámica del ganador.
- Los indicadores sectoriales son series **originales**, coherentes con el RMarkdown de estimación.
- El Excel IVS se valida por hoja, filas, columnas y encabezados antes de estimar.
- Las credenciales del BCCh se leen exclusivamente desde variables de entorno o GitHub Secrets.
- Los intervalos del 80% son condicionales al modelo y no incorporan toda la incertidumbre por revisiones estadísticas.

Última ejecución publicada: **{{ imacec.updated }}**.

## Archivos principales

{% if imacec.ready %}
<div class="download-grid">
  <a class="download" href="../assets/files/imacec-nowcast-summary.csv"><div><strong>Nowcasts por corte</strong><span>CSV · M4, M8P y EEE alineada</span></div><span>↓</span></a>
  <a class="download" href="../assets/files/imacec-oos-metrics.csv"><div><strong>Métricas pseudo OOS</strong><span>CSV · solo modelos publicados</span></div><span>↓</span></a>
</div>
{% else %}
Los archivos descargables anteriores permanecen fuera de la interfaz hasta que la primera ejecución M4/M8P sustituya de forma verificable las salidas heredadas.
{% endif %}
