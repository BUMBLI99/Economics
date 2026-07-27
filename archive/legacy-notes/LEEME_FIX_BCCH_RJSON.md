# Fix BCCh: usar la llamada original de ExchangeReg

Este parche corrige la capa de descarga BCCh del proyecto de estrés financiero.

## Problema corregido

El error:

```text
BCCh devolvió una respuesta no JSON ... valor ausente donde TRUE/FALSE es necesario
```

venía de la combinación `httr::GET()` + `jsonlite::fromJSON()` que agregué en el wrapper nuevo. El proyecto original `ExchangeReg` no usaba esa vía para BCCh: usaba directamente:

```r
rjson::fromJSON(file = url)
```

Este parche vuelve a esa lógica original.

## Archivos reemplazados

- `R/estres_financiero/00_setup.R`
- `R/estres_financiero/01_fetch_sources.R`
- `scripts/06_update_estres_financiero.R`

## Antes de correr

Si no tienes `rjson`, instala:

```r
install.packages("rjson")
```

Luego fuerza descarga live para verificar:

```r
Sys.setenv(ESTRES_USE_LIVE = "TRUE")
Sys.setenv(ESTRES_FALLBACK_LOCAL = "FALSE")
source("scripts/06_update_estres_financiero.R")
```

Lo esperado es:

```text
Fuente efectiva: live_bcch_fred_bis
```
