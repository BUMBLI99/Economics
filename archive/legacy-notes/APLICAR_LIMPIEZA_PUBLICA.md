# Ajuste de redacción pública del portafolio

Cambios aplicados en esta versión:

- Se eliminaron de las páginas públicas las secciones operativas de actualización del proyecto.
- Se retiraron comandos visibles de ejecución, commit y actualización desde las notas de proyecto.
- Se ajustaron textos que sonaban demasiado internos o de herramienta, privilegiando una redacción más propia de nota técnica económica.
- Se mantuvieron los detalles metodológicos relevantes para evaluar los proyectos: fuentes, variables, especificaciones, cautelas e interpretación.

## Aplicación sugerida

Desde PowerShell, copiar el contenido del ZIP sobre el repositorio, renderizar y subir:

```powershell
$REPO = "D:\Users\mullo\Documents\GitHub\Economics"
$UPDATE = "D:\Users\mullo\Downloads\Economics_public_cleanup\Economics"

cd $REPO
robocopy $UPDATE $REPO /E /XD .git .Rproj.user .quarto _freeze /XF .Renviron .RData .Rhistory
quarto render
git add .
git commit -m "Limpia redaccion publica y secciones internas del portafolio"
git push
```
