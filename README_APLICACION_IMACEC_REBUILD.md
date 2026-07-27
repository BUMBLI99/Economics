# Parche: reconstrucción de la página IMACEC

Este parche rehace la página `proyectos/imacec.qmd` para que muestre el flujo mensual correcto del proyecto:

1. **EEE** del mes objetivo.
2. **Modelo base** cuando ya hay estadísticas experimentales.
3. **Modelo INE** cuando ya están disponibles los indicadores sectoriales.
4. **Dato efectivo** cuando el IMACEC oficial se publica.

También:
- recupera los recuadros de estado arriba,
- deja la evaluación pseudo out-of-sample desde **2021-01**,
- agrega los gráficos finales de calendario:
  - `draw_calendario_2panel(g_cal_total_2panel)`
  - `draw_calendario_2panel(g_cal_nm_2panel)`
  - `g_indice_calendario`
- vuelve a exportar/actualizar:
  - `imacec_update_status.csv`
  - `imacec_projection_archive.csv`
  - `imacec_projection_evaluation.csv`
  - `imacec_assumptions.csv`

## Aplicación

Copia el contenido de esta carpeta sobre la raíz del repo `Economics`, sobrescribiendo:

- `proyectos/imacec.qmd`
- `R/imacec_outputs.R`
- `scripts/01_update_imacec.R`
- `assets/css/styles.css`

Luego ejecuta:

```powershell
cd "D:\Users\mullo\Documents\GitHub\Economics"
$env:IMACEC_EVAL_START_DATE="2021-01-01"
Rscript scripts/01_update_imacec.R
quarto render proyectos/imacec.qmd
```
