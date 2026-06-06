# Notas de reorganización

## Núcleo final identificado

El flujo operativo actual usa:

- `readmodel_alternativo.m`
- `minimep0.model`
- `history.csv`
- `step01_identificar_shocks_ipom.m`
- `step02_fcast_alt_ipom.m`

La lógica económica central no fue reescrita. La limpieza se concentró en rutas, estructura, nombres de pasos y separación de archivos heredados.

## Cambios realizados

1. Se creó `config_ipom.m` para centralizar rutas y evitar dependencia del directorio actual.
2. Se creó `startup_ipom.m` para agregar al path solo las carpetas necesarias.
3. Se creó `run_project.m` como entrada única del pipeline final.
4. Se renombraron scripts finales a `step01_*` y `step02_*` para que el orden sea explícito.
5. Se movieron datos y salidas a `data/` y `output/`.
6. Se separaron scripts antiguos en `src/matlab/legacy/`.
7. Se dejaron outputs históricos antiguos en `archive_legacy/`, fuera del flujo principal.
8. Se omitieron archivos temporales o de sesión como `.RData`, `.Rhistory`, `~$*.xlsx` y carpetas temporales `tp*`.

## Limitación

No se ejecutó MATLAB/IRIS dentro del entorno de ChatGPT porque no está disponible aquí. La revisión realizada fue estructural/estática: rutas, dependencias visibles, scripts finales y empaquetado reproducible.
