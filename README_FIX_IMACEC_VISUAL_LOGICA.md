# Fix IMACEC: visualización, flujo y evaluación

Este parche corrige la página pública `proyectos/imacec.qmd` después de los cambios que dejaron gráficos colapsados y una presentación poco legible.

## Cambios

- Elimina el JavaScript de autorango que podía colapsar el eje X.
- Vuelve a gráficos Plotly robustos, con más altura, eje Y cada 5 puntos y sin rangeslider inferior.
- Recupera recuadros superiores con mes proyectado, fuente activa, nowcast y fecha de actualización.
- Mejora la tabla principal y las tablas de evaluación usando `gt`.
- Reescribe el flujo metodológico como explicación legible, no como bloque de código.
- Mantiene el modelo con estadísticas experimentales como fuente/modelo explícito.
- Cambia la evaluación pseudo out-of-sample por defecto a 2021-01.
- Mantiene `code-tools: false` y restringe el render público a las páginas del sitio.

## Aplicación

Copiar el contenido del parche dentro de la raíz del repo `Economics`, sobrescribiendo archivos.

Luego ejecutar:

```powershell
cd "D:\Users\mullo\Documents\GitHub\Economics"

$env:IMACEC_EVAL_START_DATE="2021-01-01"
& "C:\Program Files\R\R-4.3.2\bin\x64\Rscript.exe" "scripts\01_update_imacec.R"

quarto render --execute

git add _quarto.yml proyectos\imacec.qmd R\imacec_outputs.R scripts\01_update_imacec.R assets\css\styles.css docs data\processed assets\img\imacec
git commit -m "Corrige visualizacion y evaluacion IMACEC"
git push
```
