# Proyecto IPOM/IRIS-MATLAB ordenado

Versión auditada del proyecto. El objetivo es preservar el modelo/forecast final y separar claramente el pipeline activo del material histórico.

## Ejecutar pipeline final

En MATLAB, abre esta carpeta como directorio de trabajo y ejecuta:

```matlab
run_project
```

Esto usa el `history.csv` ya incluido y genera/actualiza:

- `output/raw/fcast_ipom_exact.csv`
- `output/raw/fcast_ipom_with_shocks.csv`
- `output/raw/fcast_alt_petroleo_gap.csv`
- `output/raw/fcast_alt_escenario.csv`

## Si actualizaste Data.csv desde R

```matlab
IPOM_REBUILD_HISTORY = true;
run_project
```

Eso equivale a correr el `makedata` moderno antes del forecast.

También puedes correr solo la etapa de historia:

```matlab
run_build_history
```

## Reportes PDF IRIS

Por defecto no se generan PDFs para mantener el pipeline liviano. Para generarlos:

```matlab
IPOM_RUN_REPORT = true;
run_project
```

## Estructura

```text
config_ipom.m                 rutas centralizadas
startup_ipom.m                inicialización de path
run_project.m                 pipeline principal
run_build_history.m           reconstruye history.csv desde Data.csv
src/matlab/model/             modelo IRIS activo
src/matlab/scripts/           pasos activos del pipeline
src/r/                         Rmd principal de estimaciones/datos
src/r/archive_exploratory/     Rmd exploratorio antiguo
data/raw/                      Data.csv y ponderadores
data/processed/                history.csv para IRIS
output/raw/                    CSV finales del modelo
output/reports/                PDFs IRIS si se generan
archive_legacy/                scripts y salidas anteriores fuera del path activo
docs/                          auditoría y explicación de dependencias
```

## Qué versión usar

Usa esta versión auditada. La versión `clean_fixed` solo corregía el error de `cfg`; esta además reubica correctamente `makedata`, documenta dependencias y saca el pipeline viejo del área activa.


## Actualizar datos desde R

Copia `.Renviron.example` como `.Renviron`, completa tus credenciales y ejecuta desde R/RStudio:

```r
source("run_update_data_from_r.R")
```

Luego, en MATLAB, si quieres reconstruir `history.csv` desde el nuevo `Data.csv`:

```matlab
IPOM_REBUILD_HISTORY = true;
run_tpm45_2026
```
