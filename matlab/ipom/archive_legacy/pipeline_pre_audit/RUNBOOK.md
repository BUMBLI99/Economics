# Runbook operativo IPoM / IRIS

## 1. Correr el flujo IRIS desde MATLAB

Este proyecto esta preparado para IRIS Toolbox Release 20191112. La activacion se hace dentro de `setup_ipom_project.m` usando:

```matlab
addpath C:\IRIS-Toolbox-Release-20191112
irisstartup
```

Desde MATLAB, corre:

```matlab
cd('D:\Users\mullo\Documents\GitHub\Economics\matlab\ipom\src')
run_all_ipom
```

El flujo ejecuta:

```text
setup_ipom_project.m
identificar_shocks_ipom.m
fcast_alt_ipom.m
```

Los CSV crudos se guardan directamente en:

```text
matlab/ipom/outputs/raw_iris/
```

Ya no se depende de copiar archivos a `runtime/`. Esa carpeta queda solo como respaldo/legacy.

## 2. Actualizar Quarto despues de correr IRIS

Desde la raiz del repositorio:

```powershell
Rscript scripts/03_build_ipom_outputs.R
quarto render
```

La pagina resultante queda en:

```text
docs/proyectos/ipom-iris.html
```

## 3. Actualizar la pagina sin recalcular IRIS

Si solo quieres reconstruir los CSV limpios o la pagina con los ultimos `fcast_*.csv` ya existentes:

```powershell
Rscript scripts/03_build_ipom_outputs.R
quarto render
```

## 4. Cambiar un escenario

Edita solamente este bloque en:

```text
matlab/ipom/src/fcast_alt_ipom.m
```

Busca la seccion:

```text
2.3 Ejemplo de escenario: editar aqui
```

Regla de interpretacion:

- Variables en `100*log(nivel)`: usar multiplicadores. Ejemplo: `0.95` implica caida aproximada de 5%.
- Variables en nivel/tasas/brechas: usar aditivos. Ejemplo: `+0.25` implica 25 puntos base si la variable esta en porcentaje.
- Multiplicador `1`: no se impone la variable.
- Aditivo `0`: no se impone la variable.

## 5. Cambiar IRIS, horizonte operativo o reportes PDF

Edita:

```text
matlab/ipom/src/config_ipom.m
```

Campos importantes:

```matlab
cfg.irisPath          = 'C:\IRIS-Toolbox-Release-20191112';
cfg.runMakeData       = false;
cfg.runBaseline       = true;
cfg.runAlternative    = true;
cfg.runIrisPdfReports = false;
```

Si quieres reconstruir `inputs/history.csv` desde `inputs/Data.csv`, cambia:

```matlab
cfg.runMakeData = true;
```

Si quieres que IRIS genere PDFs, cambia:

```matlab
cfg.runIrisPdfReports = true;
```

## 6. Archivos que alimentan Quarto

Quarto usa:

```text
data/processed/ipom/ipom_scenarios_long.csv
data/processed/ipom/ipom_scenario_differences_long.csv
data/processed/ipom/ipom_external_assumptions.csv
data/processed/ipom/ipom_scenario_metadata.csv
data/processed/ipom/ipom_variable_metadata.csv
```

Esos archivos se construyen desde:

```text
matlab/ipom/outputs/raw_iris/fcast_*.csv
```

## 7. Que NO usar como fuente principal

No uses como fuente principal:

```text
legacy_original/reports_pdf/
legacy_original/m_files/
runtime/
```

La fuente ordenada esta en:

```text
src/
model/
inputs/
outputs/raw_iris/
```
