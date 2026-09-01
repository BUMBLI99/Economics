<div class="kpi-grid">
  <div class="kpi"><div class="kpi-label">Cobertura</div><div class="kpi-value">52</div><div class="kpi-note">comunas de la Región Metropolitana</div></div>
  <div class="kpi"><div class="kpi-label">Módulos</div><div class="kpi-value">5</div><div class="kpi-note">pobreza, municipios, seguridad, educación y vivienda</div></div>
  <div class="kpi"><div class="kpi-label">Cortes principales</div><div class="kpi-value">3</div><div class="kpi-note">2017 · 2022 · 2024</div></div>
  <div class="kpi"><div class="kpi-label">Interacción</div><div class="kpi-value">Mapa + gráficos</div><div class="kpi-note">selección sincronizada por comuna</div></div>
</div>

<div class="callout">
  <strong>Objetivo.</strong> Reunir indicadores territoriales dispersos en una interfaz común que permita comparar comunas, detectar heterogeneidad y consultar las definiciones y cautelas de cada fuente.
</div>

## Explorador territorial

El panel sincroniza el **mapa**, el ranking, las métricas y los gráficos al seleccionar una comuna. Puedes cambiar módulo, indicador, año, cobertura territorial y escala cartográfica.

<div class="dashboard-frame">
  <iframe src="../assets/dashboards/atlas-metropolitano.html" title="Atlas Metropolitano de Santiago interactivo" loading="lazy" allowfullscreen></iframe>
  <div class="dashboard-frame-note"><span>Para disponer de más espacio, abre el panel en una pestaña independiente.</span><a href="../assets/dashboards/atlas-metropolitano.html" target="_blank" rel="noopener">Abrir a pantalla completa ↗</a></div>
</div>

## Módulos e indicadores

- **Pobreza SAE:** pobreza por ingresos y multidimensional, población estimada afectada e intervalos de confianza cuando están disponibles.
- **Finanzas municipales:** dependencia del Fondo Común Municipal, autonomía fiscal, transferencias y composición del gasto.
- **Seguridad territorial:** casos policiales comunales y estadísticas institucionales de Carabineros y PDI, manteniendo separados sus universos.
- **Educación escolar:** matrícula, dependencia administrativa, SEP, PIE, asistencia, repitencia y retiros.
- **Vivienda y hogares:** tenencia, hacinamiento, servicios básicos, conectividad y composición de hogares a partir del Censo 2024.

## Diseño de la herramienta

La unidad de observación pública es la **comuna**. La interfaz permite alternar entre las 52 comunas de la Región Metropolitana y las 34 comunas del Gran Santiago. Las escalas por cuantiles favorecen la comparación espacial dentro de cada corte; la escala absoluta temporal mantiene referencias comunes cuando el indicador lo permite.

Los datos procesados y la cartografía necesaria están contenidos en la versión compilada del panel. Esto permite publicarlo como un archivo estático y evita depender de un servidor o de una sesión de R durante la consulta.

## Fuentes

El Atlas combina estimaciones comunales SAE del Ministerio de Desarrollo Social y Familia; registros municipales de SUBDERE–SINIM; estadísticas de Carabineros, PDI y CEAD; directorio, matrícula, rendimiento y SEP del Centro de Estudios MINEDUC; microdatos de viviendas y hogares del Censo 2024; y cartografía y población del INE.

## Límites de interpretación

- El cambio metodológico de las estimaciones SAE 2024 impide leer su variación frente a 2017 o 2022 como una comparación completamente homogénea.
- Los montos municipales nominales no deben compararse entre años como si estuvieran expresados en pesos reales.
- Los casos policiales son registros administrativos: no equivalen a victimización ni a la incidencia real de delitos.
- Los indicadores educacionales combinan fuentes con fechas de corte diferentes y deben interpretarse como descripciones territoriales.
- Los indicadores construidos por el Atlas, como algunos agrupamientos de delitos o proxies de materialidad, no son indicadores oficiales de las instituciones fuente.

## Publicación liviana

La publicación distribuye únicamente el **HTML compilado** y las librerías visuales necesarias. Los datos comunales agregados y la cartografía están contenidos en el propio panel; por eso los gráficos funcionan sin subir las bases originales ni redistribuir microdatos individuales.

Leaflet y una versión reducida de Plotly se sirven desde el mismo sitio para evitar que un bloqueo o demora de servidores externos deje vacío el mapa. Solo las teselas cartográficas de fondo requieren conexión; los polígonos comunales y los datos permanecen disponibles en el archivo publicado.
