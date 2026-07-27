# Fix y10_clp live para índice de estrés financiero Chile

Este parche corrige el fallo:

```text
Muy pocas observaciones para estimar modelo de tasa soberana 10Y: 0
```

## Causa

La descarga live sí llegaba hasta BCCh/FRED/BIS, pero la serie `y10_clp` podía quedar sin observaciones útiles por problemas de parsing de fecha/número en la respuesta de BCCh. Entonces el modelo de tasa 10Y recibía 0 filas completas.

## Cambios

- Parser de fechas más robusto para BCCh/BIS/FRED:
  - `dd-mm-YYYY`
  - `YYYY-mm-dd`
  - `YYYY-mm-ddTHH:MM:SS`
  - `dd.mm.YYYY`
  - formatos con meses abreviados español/inglés.
- Parser numérico más robusto:
  - `5,67` -> `5.67`
  - `1.234,56` -> `1234.56`
- Validación explícita de cobertura de series live.
- Archivo de cobertura:

```text
data/raw/estres_financiero/live_series_coverage.csv
```

- Respaldo interno para `y10_clp` solo si el BCP 10Y diario no queda usable: usa la serie mensual BCCh `F022.BCP.TIN.AN10.NO.Z.M`, interpolada al calendario diario. Se mantiene el concepto BCP 10Y; no se cambia a swap/cámara.

## Cómo correr

Desde la raíz del repo:

```r
Sys.setenv(ESTRES_USE_LIVE = "TRUE")
Sys.setenv(ESTRES_FALLBACK_LOCAL = "FALSE")
source("scripts/06_update_estres_financiero.R")
```

Debe terminar con fuente efectiva live.
