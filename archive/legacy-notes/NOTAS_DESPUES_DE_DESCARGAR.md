# Notas después de descargar el ZIP

Este ZIP deja adelantada la incorporación del proyecto **Escenarios macroeconómicos inspirados en IPoM** al sitio Quarto.

## 1. Qué quedó agregado

### Página nueva

- `proyectos/ipom-iris.qmd`

Es la página pública del proyecto. Lee archivos procesados desde `data/processed/ipom/` y muestra:

- arquitectura del proyecto;
- escenarios disponibles;
- gráficos interactivos de inflación total, inflación subyacente, TPM y brecha de actividad;
- tabla de supuestos externos;
- diferencias frente al baseline IPoM;
- tabla resumen de impactos.

### Tarjeta en la página de proyectos

Se actualizó:

- `proyectos.qmd`

La tarjeta del proyecto IPoM ahora enlaza a `proyectos/ipom-iris.qmd`.

### Scripts R nuevos

- `R/ipom_config.R`
- `R/ipom_utils.R`
- `R/ipom_plots.R`
- `scripts/03_build_ipom_outputs.R`

Estos scripts permiten tomar CSV exportados desde IRIS/Matlab y construir bases limpias para Quarto.

### Carpeta Matlab/IRIS ordenada

- `matlab/ipom/model/minimep0.model`
- `matlab/ipom/src/readmodel_alternativo.m`
- `matlab/ipom/src/readmodel_original.m`
- `matlab/ipom/src/identificar_shocks_ipom_original.m`
- `matlab/ipom/src/fcast_alt_ipom_original.m`
- `matlab/ipom/src/makedata_original.m`
- `matlab/ipom/src/run_ipom_pipeline.m`
- `matlab/ipom/src/exportar_outputs_quarto.m`
- `matlab/ipom/outputs/*.csv`

La carpeta `outputs/` contiene algunos CSV ya generados desde tu ZIP original para que la página pueda renderizar sin correr Matlab inmediatamente.

### Bases procesadas listas

- `data/processed/ipom/ipom_scenarios_long.csv`
- `data/processed/ipom/ipom_scenarios_wide.csv`
- `data/processed/ipom/ipom_scenario_differences_long.csv`
- `data/processed/ipom/ipom_scenario_differences_summary.csv`
- `data/processed/ipom/ipom_external_assumptions.csv`
- `data/processed/ipom/ipom_variable_metadata.csv`
- `data/processed/ipom/ipom_scenario_metadata.csv`
- `data/processed/ipom/ipom_metadata.yml`

Estas bases son las que consume la página Quarto.

## 2. Qué hacer apenas descargues

Desde la raíz del proyecto:

```powershell
quarto render
```

Luego abre:

```text
docs/proyectos/ipom-iris.html
```

Si todo está bien, deberías ver la nueva página IPoM dentro del sitio.

## 3. Si Quarto dice que faltan paquetes de R

Instala estos paquetes:

```r
install.packages(c(
  "dplyr", "tidyr", "readr", "ggplot2", "plotly", "knitr", "tibble"
))
```

Después vuelve a ejecutar:

```powershell
quarto render
```

## 4. Cómo actualizar los resultados cuando cambies Matlab/IRIS

El flujo recomendado es:

```powershell
# 1. Correr o actualizar tus simulaciones Matlab/IRIS
# Los CSV deben quedar en matlab/ipom/outputs/

# 2. Regenerar bases limpias para Quarto
Rscript scripts/03_build_ipom_outputs.R

# 3. Renderizar sitio
quarto render
```

Si quieres intentar el wrapper PowerShell:

```powershell
.\scripts\04_run_ipom_matlab.ps1
Rscript scripts/03_build_ipom_outputs.R
quarto render
```

Pero ojo: `run_ipom_pipeline.m` todavía está como wrapper seguro. No ejecuta automáticamente tus scripts originales porque algunos pueden depender de rutas locales o decisiones manuales de escenario. Hay que editarlo y activar el flujo exacto cuando estés listo.

## 5. Qué hay que revisar manualmente después

### A. Revisar los nombres de escenarios

Ahora dejé nombres razonables:

- `Baseline IPoM identificado`
- `Fin anticipado conflicto Irán`
- `Risk-off global`
- `Escenario alternativo`
- `Baseline modelo sin juicio IPoM`

Si quieres nombres más formales para el portafolio, edita:

```text
R/ipom_config.R
```

### B. Confirmar ventana de publicación

Las tablas de impactos usan por defecto 2025-2027. Puedes cambiarlo en:

```text
scripts/03_build_ipom_outputs.R
```

o directamente dentro de:

```text
R/ipom_utils.R
```

argumentos:

```r
forecast_start_year = 2025
forecast_end_year = 2027
```

### C. Revisar variables exógenas/endógenas por escenario

La página todavía describe el flujo general. Falta agregar una tabla específica por escenario con:

- variables exogenizadas;
- shocks endogenizados;
- horizonte de imposición;
- interpretación económica del shock.

Ese sería el siguiente paso metodológico más importante.

### D. Ordenar los scripts Matlab originales

Preservé tus scripts originales con sufijo `_original.m`. Conviene convertirlos después en funciones más limpias, por ejemplo:

```text
identificar_baseline_ipom.m
simular_escenario_externo.m
simular_riskoff_global.m
simular_iran_fin_anticipado.m
```

La meta es que cada script reciba parámetros y exporte un CSV sin intervención manual.

### E. No subir credenciales

No subas `.Renviron`, claves del Banco Central, FRED API keys, usuarios ni contraseñas.

El `.gitignore` ya excluye `.Renviron`, pero revisa antes de hacer commit:

```powershell
git status
```

## 6. Comandos Git sugeridos

Después de revisar que renderiza:

```powershell
git status
git add .
git commit -m "Agrega proyecto IPoM IRIS al sitio Quarto"
git push
```

## 7. Limitación de este ZIP

No pude renderizar el sitio dentro del entorno donde se preparó el ZIP porque ahí no estaban instalados `Rscript` ni `quarto`. Por eso dejé los archivos listos, los CSV procesados ya creados y los scripts de reconstrucción, pero la validación final debe hacerla tu máquina con R y Quarto instalados.
