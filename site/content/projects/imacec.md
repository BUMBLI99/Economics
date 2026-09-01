<div class="kpi-grid">
  <div class="kpi"><div class="kpi-label">Mes objetivo</div><div class="kpi-value">{{ imacec.target }}</div><div class="kpi-note">siguiente IMACEC por publicar</div></div>
  <div class="kpi"><div class="kpi-label">IMACEC total</div><div class="kpi-value">{{ imacec.total }}%</div><div class="kpi-note">intervalo 95%: {{ imacec.total_lwr }} a {{ imacec.total_upr }}</div></div>
  <div class="kpi"><div class="kpi-label">No minero</div><div class="kpi-value">{{ imacec.nonmining }}%</div><div class="kpi-note">intervalo 95%: {{ imacec.nonmining_lwr }} a {{ imacec.nonmining_upr }}</div></div>
  <div class="kpi"><div class="kpi-label">Vintage vigente</div><div class="kpi-value">Experimental</div><div class="kpi-note">indicadores sectoriales INE aún no disponibles</div></div>
</div>

<div class="callout callout-warning">
  <strong>Lectura de estado.</strong> Para {{ imacec.target }}, el pipeline dispone de estadísticas experimentales, pero no del bloque sectorial INE completo. Por eso la página publica únicamente el nowcast efectivamente disponible y no presenta la proyección INE como si estuviera operativa.
</div>

## Pregunta económica

¿Es posible anticipar el crecimiento anual del **IMACEC total** y del **IMACEC no minero** antes de la publicación oficial, respetando el conjunto de información que realmente estaba disponible en cada momento del ciclo mensual?

El proyecto se construye como un sistema de **vintages**. Cada actualización reconoce tres estados distintos:

1. **Primera señal:** estadísticas experimentales y variables de alta frecuencia.
2. **Información sectorial:** minería, manufactura, comercio, servicios y electricidad cuando el INE ha publicado el bloque necesario.
3. **Cierre del ciclo:** dato efectivo del IMACEC, que reemplaza la proyección y permite evaluar el error.

## Resultado vigente

<div class="interactive-card" data-project-chart="imacec" data-url="../assets/data/project_charts.json">
  <div class="chart-controls"><label for="imacec-dataset">Serie</label><select id="imacec-dataset" data-dataset-select></select></div>
  <div class="interactive-chart" data-generic-chart aria-live="polite"></div><div class="chart-legend" data-chart-legend></div>
</div>

La estimación para **{{ imacec.target }}** apunta a una variación anual de **{{ imacec.total }}%** en el IMACEC total y de **{{ imacec.nonmining }}%** en el componente no minero. La divergencia sugiere una lectura de actividad agregada débil, pero con mejor desempeño fuera del componente minero.

Estas cifras deben interpretarse junto con sus intervalos y con el estado del ciclo informativo. No son una publicación oficial ni una estimación en tiempo real libre de revisiones.

<figure class="chart-figure">
  <a href="../assets/img/charts/imacec_total_history.svg" target="_blank"><img src="../assets/img/charts/imacec_total_history.svg" alt="IMACEC total efectivo, ajustes de modelos y nowcast vigente"></a>
  <figcaption class="chart-caption">Serie completa disponible. El punto de proyección corresponde solo al modelo activo para el vintage actual.</figcaption>
</figure>

<figure class="chart-figure">
  <a href="../assets/img/charts/imacec_nonmining_history.svg" target="_blank"><img src="../assets/img/charts/imacec_nonmining_history.svg" alt="IMACEC no minero efectivo, ajustes de modelos y nowcast vigente"></a>
  <figcaption class="chart-caption">El ajuste histórico de ambos modelos puede compararse, pero una proyección solo se publica cuando sus insumos existen.</figcaption>
</figure>

## Arquitectura del nowcast

<div class="equation"><span class="equation-label">Especificación general</span>y<sub>t</sub> = α + β′X<sub>t,v</sub> + γ′Calendario<sub>t</sub> + μ<sub>mes</sub> + ε<sub>t</sub></div>

El vector **X<sub>t,v</sub>** cambia con el vintage **v**. La especificación temprana usa estadísticas experimentales, crédito, ventas, UF y variables calendario. La especificación sectorial incorpora indicadores INE únicamente cuando están disponibles para el mes objetivo. Esta separación evita el uso implícito de información futura.

Los dos modelos se estiman para IMACEC total y no minero. Además del ajuste interno, se comparan con benchmarks simples: AR(1), promedio móvil de tres meses y regla estacional a doce meses.

## Evaluación pseudo out-of-sample

<figure class="chart-figure">
  <a href="../assets/img/charts/imacec_oos_rmse.svg" target="_blank"><img src="../assets/img/charts/imacec_oos_rmse.svg" alt="RMSE pseudo out-of-sample para modelos IMACEC y benchmarks"></a>
  <figcaption class="chart-caption">La evaluación comienza en 2021, pero el número de pronósticos difiere según la fecha desde la cual cada bloque de datos puede reconstruirse.</figcaption>
</figure>

{{ imacec.oos_table|safe }}

El modelo sectorial INE presenta el menor RMSE en la muestra donde puede evaluarse, pero esa comparación no es perfectamente homogénea porque cuenta con menos observaciones. La conclusión profesional no es que “gana” sin condiciones, sino que **agrega información útil cuando el bloque sectorial está efectivamente disponible**.

## Qué se corrigió en esta versión

- La página ya no mezcla proyecciones de meses anteriores con el vintage vigente.
- El modelo INE desaparece del bloque de proyección cuando sus insumos no están disponibles.
- Los gráficos distinguen efectivo, ajuste de cada modelo y nowcast con formas y trazos diferentes.
- La evaluación pseudo out-of-sample informa el tamaño muestral de cada comparación.
- La publicación consume archivos procesados; una falla de descarga no destruye el sitio completo.

## Límites de interpretación

- La evaluación es **pseudo** out-of-sample: utiliza la base final reconstruida y no todos los vintages históricos en tiempo real.
- Los intervalos reflejan incertidumbre estadística condicional al modelo, no toda la incertidumbre de revisión de datos.
- Quiebres extraordinarios, como la pandemia, pueden dominar métricas agregadas.
- La disponibilidad y oportunidad de los indicadores sectoriales deben revisarse en cada actualización.

## Archivos principales

<div class="download-grid">
  <a class="download" href="../assets/files/imacec-nowcast-summary.csv"><div><strong>Resumen del nowcast</strong><span>CSV · proyección vigente</span></div><span>↓</span></a>
  <a class="download" href="../assets/files/imacec-oos-metrics.csv"><div><strong>Métricas pseudo OOS</strong><span>CSV · modelos y benchmarks</span></div><span>↓</span></a>
</div>
