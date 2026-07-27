# Actualiza IMACEC y reconstruye la página pública.
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
& $Rscript scripts/01_update_imacec.R
& (Join-Path $repo "scripts\09_rebuild_public_site.ps1")
