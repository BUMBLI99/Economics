@echo off
setlocal
cd /d "%~dp0"

REM Ejecuta sólo la etapa R/Quarto usando outputs ya existentes.
REM Para regenerar desde Matlab primero usa: powershell -ExecutionPolicy Bypass -File scripts\04_run_ipom_matlab.ps1

Rscript scripts\03_build_ipom_outputs.R
quarto render proyectos/ipom-iris.qmd
quarto render proyectos.qmd
quarto render index.qmd

echo.
echo IPOM renderizado. Revisa docs/proyectos/ipom-iris.html
