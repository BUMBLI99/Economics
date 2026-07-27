# Hotfix: modelos y datos del proyecto de estrés financiero

Este parche corrige el error:

```r
Can't select columns that don't exist.
✖ Column `clp` doesn't exist.
```

## Causa

El modelo cambiario se estima sobre `l_clp = log(clp)`. En el objeto interno de estimación quedaba `l_clp`, pero no quedaba la columna original `clp`. Luego el script intentaba seleccionar `clp` para graficar observado vs ajustado y fallaba.

Además, el respaldo local podía venir con nombres originales de `ExchangeReg` (`CLP`, `10YCLP`, `10YTSY`, etc.) en vez de nombres ya normalizados (`clp`, `y10_clp`, `y10_tsy`).

## Archivos reemplazados

- `R/estres_financiero/00_setup.R`
- `R/estres_financiero/01_fetch_sources.R`
- `R/estres_financiero/01_data.R`
- `R/estres_financiero/02_models.R`

## Cambios principales

1. El modelo FX ahora reincorpora `clp` desde `market_data` antes de construir los outputs.
2. La lectura de la base local ahora normaliza columnas originales de `ExchangeReg`.
3. `estres_safe_log()` ya no genera warnings por valores negativos de WTI.
4. Se hizo más robusta la validación de credenciales y el parsing de fechas.
5. Si la descarga live falla, el fallback local debería funcionar aunque el CSV tenga nombres originales.

## Cómo aplicarlo

Descomprime este ZIP en la raíz del repo `Economics` y acepta reemplazar archivos.

Luego corre:

```r
source("scripts/06_update_estres_financiero.R")
```

Después renderiza:

```bash
quarto render
```
