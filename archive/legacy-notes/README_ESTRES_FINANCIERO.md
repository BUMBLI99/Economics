# Índice de estrés financiero de mercado para Chile

Este módulo adapta el proyecto original `ExchangeReg` a una página profesional dentro del repositorio `Economics`, enfocada exclusivamente en Chile.

La pregunta económica es:

> ¿Cuándo el USD/CLP y la tasa soberana chilena a 10 años se alejan de lo que explican fundamentos externos observables?

## Qué contiene

```text
R/estres_financiero/
  00_setup.R
  01_data.R
  02_models.R
  03_plots.R
  04_run_pipeline.R

scripts/
  06_update_estres_financiero.R

proyectos/
  estres-externo.qmd

data/raw/estres_financiero/
  merged_full_dataset.csv

data/processed/estres_financiero/
  market_data_chile.csv
  stress_index_chile.csv
  model_coefficients.csv
  model_diagnostics.csv
  latest_snapshot.csv

outputs/tables/estres_financiero/
  episodios_estres.csv

assets/img/estres_financiero/
  stress_index_chile.png
  components_zscores_chile.png
  fx_fit_chile.png
  y10_fit_chile.png
```

## Metodología

Se estiman dos modelos descriptivos de normalización por fundamentos externos.

### 1. Tipo de cambio

```text
log(USDCLP) ~ trend + log(cobre) + log(WTI) + log(VIX) + log(dólar global) +
              log(CNY) + log(Nasdaq) + log(acciones China)
```

El residuo positivo se interpreta como presión cambiaria: el CLP está más depreciado que lo predicho por fundamentos observables.

### 2. Tasa soberana 10Y

```text
10Y_CLP ~ trend + 10Y_US + log(VIX) + log(dólar global) + log(CNY) + log(Nasdaq)
```

El residuo positivo se interpreta como presión en tasas largas: la tasa local está más alta que lo predicho por condiciones globales.

### 3. Índice agregado

Los residuos se estandarizan como z-scores y se promedian:

```text
stress_market = (z_fx + z_y10) / 2
```

La página usa también una media móvil de 30 días para facilitar la lectura visual.

## Cómo actualizar

Desde la raíz del repositorio:

```r
source("scripts/06_update_estres_financiero.R")
```

Luego renderiza el sitio:

```bash
quarto render
```

## Nota importante

Esta versión no incluye credenciales ni claves API. La base raw incluida es una versión depurada del archivo `merged_full_dataset.xlsx` de `ExchangeReg`, convertida a CSV y con nombres de columnas normalizados. La cobertura efectiva del modelo llega hasta noviembre de 2025 porque esa es la cobertura disponible en el archivo original recibido.

## Extensiones recomendadas

1. Separar un módulo de liquidez bancaria con retrocompra/retroventa CMF.
2. Agregar CDS soberano si se consigue una fuente reproducible.
3. Agregar spreads corporativos o bancarios cuando exista una serie pública estable.
4. Probar una versión robusta con ventana móvil o expansión recursiva para evitar estandarización full-sample.
5. Comparar el índice simple con PCA, pero solo si se agregan más componentes financieros.
