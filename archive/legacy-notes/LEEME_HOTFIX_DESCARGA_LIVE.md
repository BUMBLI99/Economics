# Hotfix: descarga en vivo BCCh/FRED/BIS

Este parche corrige el error:

```r
No se pudo descargar en vivo: valor ausente donde TRUE/FALSE es necesario
```

## Causa

El parser de fechas tenía una condición del tipo:

```r
if (any(bad))
```

pero `bad` podía contener `NA` cuando alguna respuesta de BCCh/BIS traía fechas vacías o valores no estándar. En R, `if (NA)` produce exactamente el error "valor ausente donde TRUE/FALSE es necesario".

## Qué corrige

- `R/estres_financiero/01_fetch_sources.R`
- `R/estres_financiero/01_data.R`

El parser ahora es tolerante a:

- fechas vacías;
- `NA`, `NaN`, `.`, `null`;
- formatos `YYYY-MM-DD`, `DD-MM-YYYY`, `DD/MM/YYYY`, `MM/DD/YYYY`;
- fechas tipo `YYYYMM` y `YYYYMMDD`.

## Cómo aplicar

Descomprime este ZIP en la raíz del repo `Economics` y acepta reemplazar archivos.

Luego ejecuta:

```r
source("scripts/06_update_estres_financiero.R")
```

Si todo está bien con credenciales y conexión, la fuente efectiva debería pasar de:

```text
local_exchange_reg_fallback
```

a:

```text
live_bcch_fred_bis
```
