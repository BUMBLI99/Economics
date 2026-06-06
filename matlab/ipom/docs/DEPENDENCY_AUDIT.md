# Auditoría de dependencias del proyecto IPOM/IRIS

## Pipeline activo recomendado

```text
src/r/estimaciones_macro_ipom_tablas.Rmd  [opcional: reconstruye Data.csv desde APIs]
        ↓
data/raw/Data.csv
        ↓
src/matlab/scripts/step00_build_history_from_data.m  [equivalente moderno de makedata.m]
        ↓
data/processed/history.csv
        ↓
src/matlab/scripts/step01_identificar_shocks_ipom.m
        ↓
output/raw/fcast_ipom_exact.csv
output/raw/fcast_ipom_with_shocks.csv
        ↓
src/matlab/scripts/step02_fcast_alt_ipom.m
        ↓
output/raw/fcast_alt_petroleo_gap.csv
output/raw/fcast_alt_escenario.csv
```

## Archivos activos mínimos

- `run_project.m`: entrada principal.
- `startup_ipom.m`: agrega al path solo carpetas activas.
- `config_ipom.m`: centraliza rutas.
- `src/matlab/model/minimep0.model`: archivo de ecuaciones IRIS.
- `src/matlab/model/readmodel_alternativo.m`: calibración/lectura activa del modelo.
- `src/matlab/scripts/step00_build_history_from_data.m`: construye `history.csv` desde `Data.csv`. Reemplaza al `makedata.m` antiguo.
- `src/matlab/scripts/makedata.m`: wrapper de compatibilidad que llama a `step00_build_history_from_data.m`.
- `src/matlab/scripts/step01_identificar_shocks_ipom.m`: identifica shocks para hacer calzar el baseline IPOM.
- `src/matlab/scripts/step02_fcast_alt_ipom.m`: simula el escenario alternativo final.
- `data/raw/Data.csv`: base R→MATLAB.
- `data/processed/history.csv`: base IRIS ya procesada.

## Qué quedó archivado y por qué

La carpeta `archive_legacy/matlab_old_pipeline/` contiene scripts que pertenecen al flujo anterior:

```text
Forecast.m → fcast_ipom.csv → alternativesAjuste.m / alternatives.m → fcast_alt.csv → Report_*.m
```

Ese flujo no es el pipeline final actual. El pipeline final usa:

```text
step01_identificar_shocks_ipom.m → fcast_ipom_exact.csv → step02_fcast_alt_ipom.m
```

Por eso `Forecast.m`, `Forecast_V2.m`, `alternatives*.m`, `Report_*.m`, `GraficosGuerra.m`, `modelproperties.m` y `readmodel.m` quedaron archivados. No se borraron porque sirven para trazabilidad, comparación o recuperación de escenarios anteriores.

## Nota importante sobre `makedata.m`

`makedata.m` no era basura. Era una etapa real de preprocesamiento. En esta versión queda reemplazada por `step00_build_history_from_data.m`, que hace el mismo trabajo esencial pero con rutas robustas:

1. lee `data/raw/Data.csv`;
2. calcula `DLA_*` y `D4L_*` para las variables `L_*`;
3. construye `DLA_CPIRES = DLA_CPI - DLA_CPIXFE`;
4. guarda `data/processed/history.csv`.

Para mantener compatibilidad, también existe `src/matlab/scripts/makedata.m`, pero ahora solo llama al step00 moderno.
