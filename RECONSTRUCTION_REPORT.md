# Informe de reconstrucción del proyecto Economics

Fecha de cierre: 27 de julio de 2026.

## Alcance

La intervención reconstruyó el repositorio como un portafolio profesional integrado, manteniendo el código analítico y las salidas existentes, pero reemplazando la capa pública acumulativa por un sistema estático limpio, determinista y validable.

## Cambios estructurales

- Se separaron código analítico, datos procesados, salidas, fuente editorial, artefacto público y archivo histórico.
- `site/` pasó a ser la única fuente editorial activa y `docs/` el único artefacto publicable.
- `docs/` se limpia completamente en cada build para impedir páginas fantasma.
- Los hotfixes, notas transitorias, la antigua fuente Quarto y los launchers obsoletos quedaron fuera del flujo activo en `archive/`.
- El pipeline IPoM activo quedó separado de la disposición previa, conservada en `matlab/ipom/archive_legacy/`.
- Se corrigieron funciones de búsqueda de raíz y rutas que dependían de `_quarto.yml` o de carpetas antiguas.

## Sistema visual

- Identidad común en marfil, azul marino, teal y terracota.
- Plantillas unificadas para Inicio, índice de proyectos, páginas técnicas, CV, Contacto, 404 y redirecciones.
- Tipografía, espaciado, tarjetas, tablas, KPI, callouts, ecuaciones, descargas y gráficos estandarizados.
- Diseño responsive validado en 1440 px y 390 px, sin desbordamiento horizontal.
- Gráficos regenerados en SVG y PNG para preservar nitidez y compatibilidad.

## Revisión por proyecto

### Nowcasting IMACEC

- Se eliminó la contradicción entre disponibilidad de datos INE y proyección publicada.
- El sitio muestra únicamente el modelo realmente disponible para el vintage vigente.
- Se reorganizó la página en resultado, arquitectura, evaluación pseudo out-of-sample, correcciones y límites.
- La evaluación fuera de muestra se presenta desde 2021 y separa total y no minero.

### Escenarios macroeconómicos IPoM/IRIS

- Se corrigió el enlace desde la portada.
- Se identificó y documentó el pipeline activo.
- Se separó la versión previa del pipeline para impedir que scripts históricos entren al path operativo.
- Se normalizaron salidas para que el sitio consuma únicamente CSV consolidados.
- La página explica escenarios, resultados, estructura conceptual, bloque externo y límites.

### Transmisión de la TPM

- Se ordenaron resultados por canal: pass-through acumulado, asimetrías y local projections.
- Se estandarizó la comparación entre productos bancarios.
- Se incorporaron cautelas sobre interpretación y heterogeneidad temporal.

### Exchange LatAm

- Se reemplazó la lógica de reporte incrustado por una página nativa del portafolio.
- Se incorporaron gráficos panorámicos regionales y un selector interactivo por país.
- Se explicitaron ecuaciones de primera y segunda etapa.
- Se retiraron del sitio público secciones auxiliares que no aportaban a la narrativa principal.

### Estrés financiero Chile

- Se redefinió la página como un índice de tensión conjunta en USD/CLP y tasa soberana 10Y.
- Se documentaron primera etapa, agregación, diagnóstico y límites.
- La antigua URL `estres-externo.html` mantiene una redirección funcional.

### Curva soberana chilena

- La página consume datos procesados BCP/BCU en lugar de una demostración simulada.
- Se agregaron curva vigente, explorador histórico, pendiente y compensación inflacionaria.
- El gráfico histórico es interactivo y funciona sin dependencias externas.

## Perfil y documentación

- Se reconstruyó el CV web con experiencia, formación, tesis y herramientas.
- Se generó un CV público A4 de una página sin dirección, teléfono ni fecha de nacimiento.
- Se añadió una página de contacto funcional.
- Se reescribieron README, arquitectura, despliegue, changelog y documentación operativa.

## Automatización y publicación

- `scripts/build_site.py` genera el sitio completo.
- `scripts/validate_site.py` valida páginas, enlaces, assets, anclas, alt text y filtraciones de fuentes.
- `.github/workflows/pages.yml` construye, valida y despliega mediante GitHub Actions.
- `docs/` queda incluido y listo para el método alternativo de publicación desde rama.

## Validaciones realizadas

- Compilación de todos los scripts Python.
- Build completo del sitio.
- Verificación automática de 12 páginas HTML y todos sus enlaces internos.
- Pruebas visuales de 10 páginas en escritorio y móvil.
- Verificación de los dos dashboards interactivos.
- Verificación de ausencia de overflow móvil.
- Inspección visual del CV PDF y confirmación de una sola página A4.
- Búsqueda de rutas absolutas dependientes del equipo fuera de los archivos históricos.

## Limitación explícita

No se reestimaron los pipelines R, Matlab e IRIS dentro de este entorno porque esas herramientas, credenciales y dependencias locales no estaban disponibles. La reconstrucción conserva y ordena el código, corrige rutas visibles y construye el sitio a partir de las salidas procesadas incluidas. Antes de sustituir una serie con datos nuevos, debe ejecutarse el pipeline analítico correspondiente y luego reconstruirse el sitio.
