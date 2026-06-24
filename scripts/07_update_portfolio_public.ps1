# Ejecutar desde PowerShell, en la raíz del repositorio Economics:
#   powershell -ExecutionPolicy Bypass -File scripts\07_update_portfolio_public.ps1
#
# Actualiza outputs clave y renderiza SOLO las páginas públicas definidas en _quarto.yml.
# Importante: no renderiza Rmd internos de matlab/, modelos/, archive_exploratory/, README/LEEME, etc.

$ErrorActionPreference = "Stop"

function Find-Rscript {
  $cmd = Get-Command Rscript -ErrorAction SilentlyContinue
  if ($null -ne $cmd) { return $cmd.Source }

  $candidates = @()
  if (Test-Path "C:\Program Files\R") {
    $candidates += Get-ChildItem "C:\Program Files\R" -Recurse -Filter Rscript.exe -ErrorAction SilentlyContinue |
      Sort-Object FullName -Descending |
      Select-Object -ExpandProperty FullName
  }
  if (Test-Path "C:\Program Files (x86)\R") {
    $candidates += Get-ChildItem "C:\Program Files (x86)\R" -Recurse -Filter Rscript.exe -ErrorAction SilentlyContinue |
      Sort-Object FullName -Descending |
      Select-Object -ExpandProperty FullName
  }

  if ($candidates.Count -eq 0) {
    throw "No encontré Rscript.exe. Instala R o define Rscript en el PATH."
  }

  return $candidates[0]
}

$repo = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $repo

$RSCRIPT = Find-Rscript
Write-Host "Usando Rscript: $RSCRIPT"

Write-Host "`n1/6 Actualizando IMACEC..."
& $RSCRIPT scripts/01_update_imacec.R

Write-Host "`n2/6 Actualizando transmisión TPM..."
& $RSCRIPT scripts/05_update_transmision_tpm.R

Write-Host "`n3/6 Actualizando estrés financiero..."
& $RSCRIPT -e "source('scripts/06_update_estres_financiero.R')"

Write-Host "`n4/6 Procesando outputs IPoM/IRIS..."
& $RSCRIPT scripts/03_build_ipom_outputs.R

Write-Host "`n5/6 Renderizando Quarto público..."
quarto render --execute

Write-Host "`n6/6 Limpiando HTML internos residuales..."
& scripts\00_clean_public_docs.bat

Write-Host "`nValidando que no se renderizó archivo interno Data_IPOM_exploratory..."
if (Test-Path "docs\matlab\ipom\src\r\archive_exploratory\Data_IPOM_exploratory.html") {
  throw "Se renderizó un Rmd interno que no debe ser público. Revisa project.render en _quarto.yml."
}

Write-Host "`nListo. Revisa estado de Git:"
git status
