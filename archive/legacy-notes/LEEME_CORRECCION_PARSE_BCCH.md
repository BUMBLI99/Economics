# Hotfix: error de parseo en 01_fetch_sources.R

Este parche corrige el error:

```r
Error in source(...01_fetch_sources.R): inesperado '='
49: lastdate = last_date,
50: function =
```

## Causa

`function` es una palabra reservada en R. En una lista de parámetros para `httr::GET()`, debe escribirse con backticks:

```r
`function` = "GetSeries"
```

## Archivo reemplazado

- `R/estres_financiero/01_fetch_sources.R`

## Cómo aplicar

Descomprime este ZIP en la raíz del repositorio `Economics` y acepta reemplazar el archivo.

Luego corre:

```r
source("scripts/06_update_estres_financiero.R")
```
