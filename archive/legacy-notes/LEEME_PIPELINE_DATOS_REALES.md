# Pipeline con datos reales: estrés financiero Chile

Este parche reemplaza la versión congelada por una versión que intenta actualizar la base desde fuentes reales.

## Fuentes usadas

- **BCCh / SieteRestWS**:
  - Tasa soberana chilena 10Y: `F022.BCLP.TIS.AN10.NO.Z.D`
  - Treasury 10Y usado por BCCh: `F019.TBG.TAS.10.D`
  - Cobre: `F019.PPB.PRE.100.D`
  - Nasdaq: `F019.IBC.IND.51.D`
  - Bolsa China: `F019.IBC.IND.CHN.D`
  - IPC Chile: `G073.IPC.IND.2023.M`
- **FRED**:
  - VIX: `VIXCLS`
  - WTI: `DCOILWTICO`
  - CPI EEUU: `CPIAUCSL`
  - Treasury 10Y fallback: `DGS10`
- **BIS**:
  - USD/CLP: `WS_XRU / D.CL.CLP.A`
  - CNY/USD: `WS_XRU / D.CN.CNY.A`
  - Dólar efectivo nominal EEUU: `WS_EER / D.N.B.US`

Nota: el proyecto original usaba **BIS**, no BID, para tipos de cambio y dólar efectivo. Por eso el pipeline queda BCCh + FRED + BIS.

## Archivos nuevos o reemplazados

- `R/estres_financiero/00_setup.R`
- `R/estres_financiero/01_fetch_sources.R`
- `R/estres_financiero/01_data.R`
- `R/estres_financiero/02_models.R`
- `R/estres_financiero/03_plots.R`
- `R/estres_financiero/04_run_pipeline.R`
- `scripts/06_update_estres_financiero.R`
- `proyectos/estres-externo.qmd`
- `.Renviron.example`

## Configuración necesaria

Copia `.Renviron.example` a tu `.Renviron` real o agrega estas líneas a tu `.Renviron` actual:

```r
BCCH_USER=tu_usuario_bcch
BCCH_PASS=tu_password_bcch
FRED_API_KEY=tu_api_key_fred
ESTRES_USE_LIVE=TRUE
ESTRES_FALLBACK_LOCAL=TRUE
ESTRES_START_DATE=2010-01-01
```

Luego reinicia RStudio.

## Ejecución

Desde la raíz del repo `Economics`:

```r
source("scripts/06_update_estres_financiero.R")
```

Luego:

```bash
quarto render
```

## Comportamiento del pipeline

Por defecto intenta:

```text
BCCh / FRED / BIS -> data/raw/estres_financiero/market_data_live.csv -> modelos -> gráficos -> página
```

Si alguna API falla y `ESTRES_FALLBACK_LOCAL=TRUE`, usa:

```text
data/raw/estres_financiero/merged_full_dataset.csv -> modelos -> gráficos -> página
```

La página muestra la fuente efectiva en el bloque de lectura rápida.
