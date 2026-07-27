# Actualización integrada de outputs y reconstrucción del portafolio.
# Requiere .Renviron local con las credenciales utilizadas por cada fuente.
$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent $PSScriptRoot
Set-Location $repo

function Find-Rscript {
  $cmd = Get-Command Rscript -ErrorAction SilentlyContinue
  if ($null -ne $cmd) { return $cmd.Source }
  $roots = @("C:\Program Files\R", "C:\Program Files (x86)\R")
  foreach ($root in $roots) {
    if (Test-Path $root) {
      $candidate = Get-ChildItem $root -Recurse -Filter Rscript.exe -ErrorAction SilentlyContinue |
        Sort-Object FullName -Descending | Select-Object -First 1 -ExpandProperty FullName
      if ($candidate) { return $candidate }
    }
  }
  throw "No encontré Rscript.exe."
}

$Rscript = Find-Rscript
$steps = @(
  @{ Name = "IMACEC"; Script = "scripts/01_update_imacec.R" },
  @{ Name = "Transmisión TPM"; Script = "scripts/05_update_transmision_tpm.R" },
  @{ Name = "Estrés financiero Chile"; Script = "scripts/06_update_estres_financiero.R" },
  @{ Name = "Procesamiento IPoM/IRIS"; Script = "scripts/03_build_ipom_outputs.R" },
  @{ Name = "Exchange LatAm"; Script = "scripts/exchange/build_exchange_outputs.R" }
)

$i = 0
foreach ($step in $steps) {
  $i++
  Write-Host "`n[$i/$($steps.Count + 1)] $($step.Name)..." -ForegroundColor Cyan
  & $Rscript $step.Script
  if ($LASTEXITCODE -ne 0) { throw "Falló: $($step.Name)" }
}

Write-Host "`n[$($steps.Count + 1)/$($steps.Count + 1)] Construyendo y validando el sitio..." -ForegroundColor Cyan
& (Join-Path $repo "scripts\09_rebuild_public_site.ps1")
