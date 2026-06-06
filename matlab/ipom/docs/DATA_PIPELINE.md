# Pipeline de datos R → MATLAB/IRIS

## Dos Rmd: cuál usar

- `src/r/estimaciones_macro_ipom_tablas.Rmd`: versión más limpia y cercana a la versión buena. Construye la base, estima ecuaciones, genera tablas y contiene una exportación oculta a IRIS. Es el Rmd que conviene mantener como reporte principal.
- `src/r/archive_exploratory/Data_IPOM_exploratory.Rmd`: versión larga/exploratoria. Contiene más bloques de diagnóstico, duplicaciones y pruebas intermedias. Sirve como respaldo metodológico, no como entrada operacional diaria.

## Flujo recomendado cuando actualizas datos

1. Actualizar/knitear el Rmd principal para producir `data/raw/Data.csv`.
2. En MATLAB ejecutar:

```matlab
IPOM_REBUILD_HISTORY = true;
run_project
```

O solo reconstruir history:

```matlab
run_build_history
```

## Credenciales

Los Rmd fueron sanitizados para no guardar credenciales dentro del repositorio. Antes de ejecutar en R:

```r
Sys.setenv(BDE_USER = "tu_usuario")
Sys.setenv(BDE_PASS = "tu_password")
Sys.setenv(FRED_API_KEY = "tu_api_key")
```

También se incluyó `data/raw/Ponderadores.xls`, usado para construir crecimiento ponderado de socios comerciales.

## Uso recomendado con .Renviron

1. Copia `.Renviron.example` como `.Renviron` en la raíz del proyecto.
2. Reemplaza los valores con tus credenciales reales.
3. Desde R/RStudio, abre la raíz del proyecto y ejecuta:

```r
source("run_update_data_from_r.R")
```

Ese script lee `.Renviron`, ejecuta `src/r/estimaciones_macro_ipom_tablas.Rmd` y actualiza `data/raw/Data.csv`.


## Nota BDE / UTF-8

La descarga BDE usa `httr::GET(..., query=...)` y parseo con `jsonlite` después de normalizar encoding. Esto evita el error típico de Windows/R:

```text
Error in sub(): input string 1 is invalid UTF-8
```

Ese error aparecía cuando `rjson::fromJSON(file=url)` intentaba leer directamente una respuesta del Banco Central con bytes no UTF-8 o con caracteres especiales no escapados en la URL.
