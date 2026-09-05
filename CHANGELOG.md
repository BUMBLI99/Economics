# Changelog

## 2026-09 — Sostenibilidad de la deuda pública

- El proyecto de estrés financiero fue reemplazado por una DSA de la deuda bruta del Gobierno Central.
- Se modularizaron lectura, conciliación contable y motor de proyección en `R/sostenibilidad_deuda/`.
- Se incorporaron trayectorias y descomposición interactivas, además de un simulador de cuatro shocks.
- Los shocks de tasas de mercado ahora se transmiten gradualmente al costo efectivo del stock.
- Las antiguas URLs de estrés financiero redirigen al nuevo proyecto para no romper enlaces externos.

## 2026-09 — Ciclo mensual IMACEC

- Se incorporaron paneles interactivos separados para IMACEC total y no minero.
- El estado publicado avanza automáticamente por EEE/AR(1), M4 experimental, M8P INE y evaluación con el dato efectivo.
- M4 y M8P mantienen predictores fijos y se estiman por separado para ambas series.
- Las proyecciones se archivan por vintage para compararlas ex post sin reestimación retrospectiva.
- La EEE de la encuesta `M` se alinea estrictamente con el IMACEC de `M-1`.

## 2026-07 — Reconstrucción profesional del portafolio

### Arquitectura

- Se separó la capa pública de los pipelines R/Matlab.
- Se creó un constructor estático determinista en Python.
- `docs/` ahora se limpia por completo antes de cada publicación.
- Se agregó validación automática de enlaces, assets, anclas y plantillas.
- Se incorporó despliegue mediante GitHub Actions.

### Diseño y contenido

- Nueva identidad visual común para Inicio, Proyectos, CV y Contacto.
- Se estandarizaron seis páginas de proyectos.
- Se regeneraron gráficos en SVG y PNG con una paleta y tipografía coherentes.
- Se agregaron selectores interactivos para Exchange y curva soberana.
- Se creó un CV público sanitizado de una página.

### Correcciones funcionales

- El proyecto IPoM vuelve a enlazar a su página correcta.
- La página IMACEC no publica el modelo INE cuando sus insumos no están disponibles.
- Se eliminaron páginas fantasma dejadas por builds anteriores.
- `estres-externo.html` redirige al nuevo proyecto de estrés financiero.
- La curva de rendimiento dejó de usar datos simulados y consume BCP/BCU procesados.

### Limpieza

- Hotfixes y notas transitorias se movieron a `archive/legacy-notes/`.
- La antigua fuente Quarto se movió a `archive/legacy-site-source/`.
- El pipeline IPoM anterior quedó fuera del path activo en `matlab/ipom/archive_legacy/`.
- Se eliminó del proyecto publicable el CV original con datos personales innecesarios.
