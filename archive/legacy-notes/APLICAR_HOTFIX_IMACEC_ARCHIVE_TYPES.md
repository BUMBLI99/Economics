# Hotfix IMACEC: tipos del archivo de vintages

Este hotfix corrige el error:

`Can't combine fecha_hora_actualizacion <datetime<UTC>> and <character>`

La causa era que `imacec_projection_archive.csv` podía tener `fecha_hora_actualizacion` leído como datetime desde ejecuciones anteriores, mientras que la nueva observación se generaba como character. Ahora `R/imacec_outputs.R` normaliza tipos antes de `bind_rows()`.

## Aplicación

```powershell
$REPO = "D:\Users\mullo\Documents\GitHub\Economics"
$UPDATE = "D:\Users\mullo\Downloads\Economics_imacec_archive_type_hotfix\Economics"

cd $REPO
robocopy $UPDATE $REPO /E /XD .git .Rproj.user .quarto _freeze /XF .Renviron .RData .Rhistory

& $RSCRIPT scripts/01_update_imacec.R
```

Si termina bien:

```powershell
quarto render
git add .
git commit -m "Corrige archivo histórico de proyecciones IMACEC"
git push
```
