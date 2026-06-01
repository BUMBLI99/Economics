# Fix IMACEC: ciclo mensual EEE → experimentales → INE → oficial

Este ajuste corrige la lógica de avance del nowcast IMACEC.

## Qué cambia

- La página no abre una proyección prematura para el mes siguiente si aún no existe la EEE correspondiente.
- Cuando se publica el IMACEC oficial, la página conserva el último ciclo cerrado y muestra observado, estimación propia y EEE si existe.
- Cuando aparece la EEE del siguiente mes, se abre el nuevo ciclo de nowcast.
- La EEE entra como primera señal; luego se actualiza con indicadores experimentales/BCCh; finalmente, con indicadores sectoriales INE.
- La EEE se mantiene como punto de comparación en el gráfico cuando aparecen vintages posteriores.
- Los gráficos vuelven a ocupar una sección completa cada uno; se corrige el problema de divs abiertos en `imacec.qmd`.

## Aplicación

```powershell
$REPO = "D:\Users\mullo\Documents\GitHub\Economics"
$UPDATE = "D:\Users\mullo\Downloads\Economics_imacec_monthly_cycle_fix\Economics"

cd $REPO
robocopy $UPDATE $REPO /E /XD .git .Rproj.user .quarto _freeze /XF .Renviron .RData .Rhistory

& $RSCRIPT scripts/01_update_imacec.R
quarto render

git status
git add .
git commit -m "Corrige ciclo mensual del nowcast IMACEC"
git push
```

No hacer commit si `scripts/01_update_imacec.R` falla.
