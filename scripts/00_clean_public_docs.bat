@echo off
setlocal
cd /d "%~dp0\.."

echo Limpiando HTML publicos internos en docs...
if exist docs\LEEME*.html del /q docs\LEEME*.html
if exist docs\INSTRUCCIONES*.html del /q docs\INSTRUCCIONES*.html
if exist docs\README*.html del /q docs\README*.html
if exist docs\NOTAS*.html del /q docs\NOTAS*.html
if exist docs\matlab rmdir /s /q docs\matlab

echo.
echo Limpieza lista.
echo Si tienes Quarto y R configurados, ahora ejecuta: quarto render
echo Luego revisa git status, commit y push.
endlocal
