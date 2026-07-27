# Índice de archivos legacy

## `archive_legacy/pipeline_pre_audit/`

- `Forecast.m`, `Forecast_V2.m`: baseline antiguo que guardaba `fcast_ipom.csv`. Reemplazado por `step01_identificar_shocks_ipom.m`, que genera `fcast_ipom_exact.csv` y preserva shocks identificados.
- `alternatives.m`: escenario alternativo global/risk-off antiguo basado en `fcast_ipom.csv`.
- `alternativesAjuste.m`, `alternativesAjuste_GuerraLargas.m`: escenarios de guerra/ajuste antiguos basados en `fcast_ipom.csv` y `fcast_alt.csv`.
- `Report_*.m`, `GraficosGuerra.m`: reportes viejos que corren el pipeline anterior.
- `modelproperties.m`: comparación de respuestas a shocks entre modelo viejo y alternativo. Requiere `readmodel.m`; no es parte del forecast final.
- `readmodel.m`: calibración/modelo viejo, mantenido solo para reproducir `modelproperties.m`.
- `makedata.m`: versión antigua del preprocesamiento con rutas dependientes del directorio actual. Sustituida por `src/matlab/scripts/step00_build_history_from_data.m`.

Estos archivos no están en el path activo de `startup_ipom.m`. Para usarlos, hay que agregarlos manualmente al path o copiarlos a una carpeta de trabajo separada.
