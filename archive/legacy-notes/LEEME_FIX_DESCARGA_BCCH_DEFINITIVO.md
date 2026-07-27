# Fix descarga BCCh/FRED/BIS para estrés financiero

Este parche reemplaza la capa de descarga que estaba cayendo al fallback.

## Cambios principales

- La descarga BCCh ya no usa `rjson::fromJSON(file = url)` directamente.
- BCCh se descarga con `httr::GET()`, se lee como bytes y se normaliza el encoding (`UTF-8`, `latin1`, `CP1252`) antes de parsear JSON.
- Si BCCh/BIS devuelven HTML, XML o texto de error en vez de JSON/CSV, se guarda diagnóstico en:

```text
data/raw/estres_financiero/diagnostics/
```

- El script principal ya no cae al respaldo local por defecto. Para usar fallback hay que pedirlo explícitamente:

```r
Sys.setenv(ESTRES_FALLBACK_LOCAL = "TRUE")
```

## Ejecución

Desde la raíz del repo:

```r
source("scripts/06_update_estres_financiero.R")
```

Lo esperado es:

```text
Fuente efectiva: live_bcch_fred_bis
```

Si falla, revisar:

```text
data/raw/estres_financiero/live_download_error.txt
data/raw/estres_financiero/diagnostics/
```

No subas `.Renviron` al repositorio.
