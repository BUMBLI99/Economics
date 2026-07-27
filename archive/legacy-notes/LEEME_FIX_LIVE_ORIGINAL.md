# Hotfix serio: descarga live con lógica original de ExchangeReg

Este parche reemplaza la capa de descarga que estaba cayendo al fallback local.

## Archivos

- `R/estres_financiero/00_setup.R`
- `R/estres_financiero/01_fetch_sources.R`
- `R/estres_financiero/01_data.R`
- `scripts/06_update_estres_financiero.R`

## Qué cambia

1. La descarga live se reescribió siguiendo la estructura original de `ExchangeReg/Exchange.Rmd`.
2. Usa el calendario de días hábiles de BIS USD/CLP, igual que el proyecto original.
3. Descarga:
   - BCCh: tasa Chile 10Y, Treasury 10Y, cobre, Nasdaq, equity China, IPC Chile.
   - FRED: VIX, WTI, CPI US, DGS10 como fallback del Treasury.
   - BIS: USD/CLP, CNY/USD y dólar efectivo nominal EEUU.
4. Construye `cpi_rel_chl_us` diario por interpolación log-lineal mensual, igual que el enfoque original.
5. Si falla la descarga, guarda el error real en:
   - `data/raw/estres_financiero/live_download_error.txt`

## Cómo probar

En la raíz de `Economics`:

```r
Sys.setenv(ESTRES_USE_LIVE = "TRUE")
Sys.setenv(ESTRES_FALLBACK_LOCAL = "FALSE")
source("scripts/06_update_estres_financiero.R")
```

Para correr con respaldo local si una API externa está temporalmente caída:

```r
Sys.setenv(ESTRES_USE_LIVE = "TRUE")
Sys.setenv(ESTRES_FALLBACK_LOCAL = "TRUE")
source("scripts/06_update_estres_financiero.R")
```

Lo correcto, si la descarga funciona, es ver:

```text
Fuente efectiva: live_bcch_fred_bis
```
