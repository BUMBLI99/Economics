# Notas de la reestructuracion Matlab/IRIS

Cambios aplicados:

1. `setup_ipom_project.m` ahora activa IRIS Release 20191112 con `irisstartup`.
2. `run_all_ipom.m` ahora es una funcion y ya no copia scripts a `runtime/`.
3. `identificar_shocks_ipom.m` lee `history.csv` e `ipom_paths.csv` desde `matlab/ipom/inputs/`.
4. `identificar_shocks_ipom.m` guarda `fcast_ipom_exact.csv` y `fcast_ipom_with_shocks.csv` en `matlab/ipom/outputs/raw_iris/`.
5. `fcast_alt_ipom.m` lee el baseline desde `outputs/raw_iris/fcast_ipom_exact.csv`.
6. `fcast_alt_ipom.m` guarda el escenario en `outputs/raw_iris/fcast_alt_escenario.csv`.
7. `readmodel_alternativo.m` carga el modelo desde `matlab/ipom/model/minimep0.model`, no desde el directorio actual.
8. `makedata.m` reconstruye `inputs/history.csv` desde `inputs/Data.csv` solo si activas `cfg.runMakeData=true`.

Comando recomendado en MATLAB:

```matlab
cd('D:\Users\mullo\Documents\GitHub\Economics\matlab\ipom\src')
run_all_ipom
```

Despues, desde la raiz del repositorio:

```powershell
Rscript scripts/03_build_ipom_outputs.R
quarto render
```
