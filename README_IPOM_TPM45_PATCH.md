# Patch IPoM/IRIS para Economics

Este patch reemplaza el proyecto IPoM público por la corrida del zip `IPOM_IRIS_MATLAB_tpm45_2026_return_ipom_gapfix`.

## Aplicar

```powershell
cd "D:\Users\mullo\Documents\GitHub\Economics"
Expand-Archive "C:\Users\mullo\Downloads\Economics_IPOM_TPM45_2026_PATCH.zip" -DestinationPath . -Force

.\render_ipom_site.bat

git status
git add .
git commit -m "Update IPOM project with TPM 4.5 scenario"
git push
```

## Flujo completo con Matlab

Si quieres regenerar los CSV desde IRIS/Matlab:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\04_run_ipom_matlab.ps1
Rscript scripts\03_build_ipom_outputs.R
quarto render proyectos/ipom-iris.qmd
```

Para reconstruir `history.csv` desde `Data.csv`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\04_run_ipom_matlab.ps1 -RebuildHistory
```

Para pedir reportes PDF IRIS:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\04_run_ipom_matlab.ps1 -PdfReports
```
