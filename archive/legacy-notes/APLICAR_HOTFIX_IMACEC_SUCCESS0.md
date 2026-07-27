# Hotfix IMACEC: respuesta BCCh `Success 0`

Este hotfix corrige el error donde el pipeline trataba como falla una respuesta normal de la API BCCh:

```text
BCCh reportó un error para la serie ...: Success 0
```

En SieteRestWS, `Codigo = 0` y `Descripcion = Success` significa descarga exitosa. El bug estaba en `fetch_series()`, que fallaba ante cualquier presencia de `Codigo`, incluso si era cero.

También se elimina el BOM UTF-8 sin expresiones regulares para evitar errores PCRE2 con `\ufeff`.

## Aplicación

Desde PowerShell:

```powershell
$REPO = "D:\Users\mullo\Documents\GitHub\Economics"
$UPDATE = "D:\Users\mullo\Downloads\Economics_imacec_success0_hotfix\Economics"

cd $REPO
robocopy $UPDATE $REPO /E /XD .git .Rproj.user .quarto _freeze /XF .Renviron .RData .Rhistory
```

## Prueba mínima antes de correr todo

```powershell
& $RSCRIPT scripts/01_probe_bcch_imacec_fetch.R
```

Si eso imprime observaciones para IMACEC no minero e IMACEC total, corre el pipeline completo:

```powershell
& $RSCRIPT scripts/01_update_imacec.R
quarto render
git add .
git commit -m "Corrige lectura BCCh y actualiza pipeline IMACEC"
git push
```
