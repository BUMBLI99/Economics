# Ejecutar desde PowerShell, en la raíz del repositorio Economics:
#   powershell -ExecutionPolicy Bypass -File scripts\07_update_portfolio_public.ps1
#
# El script intenta encontrar Rscript.exe automáticamente, limpia docs/,
# actualiza outputs clave y renderiza el sitio Quarto.

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
Write-Host "Usando Rscript:" $RSCRIPT

Write-Host "\n1/5 Limpiando docs público..."
& scripts\00_clean_public_docs.bat

Write-Host "\n2/5 Actualizando IMACEC..."
& $RSCRIPT scripts/01_update_imacec.R

Write-Host "\n3/5 Actualizando estrés financiero..."
& $RSCRIPT -e "source('scripts/06_update_estres_financiero.R')"

Write-Host "\n4/5 Procesando outputs IPoM/IRIS..."
& $RSCRIPT scripts/03_build_ipom_outputs.R

Write-Host "\n5/5 Renderizando Quarto..."
quarto render

Write-Host "\nListo. Revisa estado de Git:"
git status
