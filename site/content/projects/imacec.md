<div class="kpi-grid imacec-cycle-kpis">
  <div class="kpi"><div class="kpi-label">Último dato efectivo</div><div class="kpi-value">{{ imacec.last_actual }}</div><div class="kpi-note">Total y no minero publicados por el BCCh</div></div>
  <div class="kpi"><div class="kpi-label">Período en seguimiento</div><div class="kpi-value">{{ imacec.target }}</div><div class="kpi-note">La EEE de M corresponde al IMACEC de M−1</div></div>
  <div class="kpi"><div class="kpi-label">Señal principal</div><div class="kpi-value">{{ imacec.default_label }}</div><div class="kpi-note">Cambia solo cuando el corte informativo está completo</div></div>
  <div class="kpi"><div class="kpi-label">Nowcast total vigente</div><div class="kpi-value">{{ imacec.principal }}</div><div class="kpi-note">No se muestra una proyección si todavía no corresponde</div></div>
</div>

<div class="callout imacec-status" data-cycle-stage="{{ imacec.stage }}">
  <strong>Estado del ciclo:</strong> {{ imacec.stage_label }}.
</div>

{% if not imacec.ready %}
<div class="callout callout-warning">
  <strong>Transición segura pendiente.</strong> La interfaz conserva únicamente el IMACEC efectivo hasta que GitHub Actions genere por primera vez el nuevo archivo de estados; ninguna cifra antigua se presenta como M4 o M8P.
</div>
{% endif %}

## Seguimiento mensual

Los dos paneles responden al mismo calendario de publicación. El selector ofrece únicamente las estimaciones realmente disponibles y deja por defecto la más informativa: señal AR(1), M4 experimental, M8P INE o resumen ex post.

### IMACEC total

<div class="interactive-card imacec-panel" data-project-chart="imacec-total" data-url="../assets/data/project_charts.json">
  <div class="chart-controls"><label for="imacec-total-dataset">Corte o resumen</label><select id="imacec-total-dataset" data-dataset-select></select></div>
  <div class="interactive-chart" data-generic-chart aria-live="polite"></div>
  <div class="chart-legend" data-chart-legend></div>
  <p class="chart-help">Pasa el cursor sobre el gráfico para consultar el IMACEC efectivo, el ajuste histórico, la proyección vigente y la EEE comparable.</p>
</div>

### IMACEC no minero

<div class="interactive-card imacec-panel" data-project-chart="imacec-nonmining" data-url="../assets/data/project_charts.json">
  <div class="chart-controls"><label for="imacec-nonmining-dataset">Corte o resumen</label><select id="imacec-nonmining-dataset" data-dataset-select></select></div>
  <div class="interactive-chart" data-generic-chart aria-live="polite"></div>
  <div class="chart-legend" data-chart-legend></div>
  <p class="chart-help">La serie no minera se estima de forma independiente, manteniendo el conjunto fijo de predictores de M4 o M8P.</p>
</div>

## Cómo se actualiza

| Momento del mes | Publicación visible | Opción predeterminada |
|---|---|---|
| Dato efectivo recién publicado, antes de la nueva EEE | IMACEC efectivo del último mes; si existen vintages válidos, resumen ex post con EEE, M4 y M8P | Resumen del período |
| Nueva EEE, antes de estadísticas experimentales | EEE alineada al mes anterior y una señal mínima AR(1) | AR(1) provisional |
| Estadísticas experimentales completas | Efectivo, ajuste M4, nowcast M4 y punto EEE | M4 · Dinámico |
| Indicadores INE e IVS completos | M4 sigue elegible y se añade M8P | M8P · INE + IVS real |
| Publicación del IMACEC objetivo | Efectivo y los puntos archivados de EEE, M4 y M8P, sin reestimarlos retrospectivamente | Resumen del período |

El archivo de vintages conserva cada proyección antes de que el dato oficial la sustituya. Así, la comparación ex post utiliza lo que el proyecto publicó realmente en cada corte y no una reconstrucción posterior con información revisada.

## Especificaciones publicadas

<div class="equation"><span class="equation-label">M4 · Dinámico — corte experimental</span>IMACEC<sub>t</sub> = f(ventas<sub>t</sub>, crédito monto<sub>t</sub>, crédito cantidad<sub>t</sub>, IMACEC<sub>t−1</sub>, calendario)</div>

<div class="equation"><span class="equation-label">M8P · INE + IVS real parsimonioso</span>IMACEC<sub>t</sub> = f(crédito cantidad<sub>t</sub>, IMACEC<sub>t−1</sub>, avisos<sub>t−1</sub>, sectores INE<sub>t</sub>, IVS real<sub>t</sub>, crédito real<sub>t</sub>, calendario)</div>

Las dos fórmulas se reestiman por separado para **IMACEC total** e **IMACEC no minero**. El factor IVS real promedia seis índices de ventas de servicios deflactados por el IPC de Servicios y M8P solo se habilita con cobertura contemporánea completa.

## Evaluación pseudo out-of-sample

{{ imacec.oos_table|safe }}

La evaluación es recursiva y mantiene fijas M4 y M8P, pero usa la base final disponible; por ello mide capacidad predictiva comparable, no reproduce todas las revisiones de cada vintage histórico.

## Reproducibilidad y publicación

- Las credenciales del BCCh se leen exclusivamente desde GitHub Actions Secrets.
- La EEE publicada en **M** se asigna al IMACEC de **M−1**.
- El proxy AR(1) aparece solamente entre la EEE y el primer corte de datos; nunca compite con M4 o M8P.
- El modelo principal cambia por disponibilidad verificable, no por cuál arroje la cifra más conveniente.
- La tarea programada revisa datos cada día hábil y solo versiona salidas cuando existe un cambio.

Última ejecución publicada: **{{ imacec.updated }}**.

## Archivos principales

{% if imacec.ready %}
<div class="download-grid">
  <a class="download" href="../assets/files/imacec-nowcast-summary.csv"><div><strong>Estado y proyecciones vigentes</strong><span>CSV · total, no minero, M4, M8P y EEE</span></div><span>↓</span></a>
  <a class="download" href="../assets/files/imacec-oos-metrics.csv"><div><strong>Métricas pseudo OOS</strong><span>CSV · dos series y dos especificaciones</span></div><span>↓</span></a>
</div>
{% endif %}
