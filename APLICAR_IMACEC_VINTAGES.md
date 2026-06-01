# Aplicar actualización del proyecto IMACEC por vintages

Esta versión reorganiza el proyecto IMACEC para que el nowcast cambie según la información disponible para el mes objetivo:

1. Vintage temprano: EEE + supuestos mecánicos para variables todavía no observadas.
2. Vintage intermedio: indicadores experimentales/BCCh y variables mensuales disponibles.
3. Vintage INE: indicadores sectoriales INE ya publicados.
4. Publicación oficial: se compara el dato efectivo contra proyecciones archivadas.

## Ejecutar desde PowerShell

```powershell
$REPO = "D:\Users\mullo\Documents\GitHub\Economics"
$UPDATE = "D:\Users\mullo\Downloads\Economics_imacec_vintages_update\Economics"

cd $REPO

robocopy $UPDATE $REPO /E /XD .git .Rproj.user .quarto _freeze /XF .Renviron .RData .Rhistory

$RSCRIPT = Get-ChildItem "C:\Program Files\R" -Recurse -Filter Rscript.exe |
  Sort-Object FullName -Descending |
  Select-Object -First 1 -ExpandProperty FullName

& $RSCRIPT scripts/01_update_imacec.R
quarto render

git status
git add .
git commit -m "Actualiza nowcast IMACEC por vintages de información"
git push
```

## Archivos nuevos/exportados

- `data/processed/imacec_update_status.csv`
- `data/processed/imacec_assumptions.csv`
- `data/processed/imacec_projection_archive.csv`
- `data/processed/imacec_projection_evaluation.csv`

El archivo `imacec_projection_archive.csv` se va acumulando con cada ejecución y permite comparar una proyección anterior contra el dato efectivo cuando el IMACEC oficial aparece en la base.
