# ============================================================
# Ejecuta el bloque Matlab/IRIS del proyecto IPoM
# ============================================================
# Uso desde PowerShell, en la raíz del repositorio:
# .\scripts\04_run_ipom_matlab.ps1
#
# Opciones:
# .\scripts\04_run_ipom_matlab.ps1 -RebuildHistory
# .\scripts\04_run_ipom_matlab.ps1 -PdfReports

param(
  [switch]$RebuildHistory,
  [switch]$PdfReports
)

$ErrorActionPreference = "Stop"

$repo = Split-Path -Parent $PSScriptRoot
$ipom = Join-Path $repo "matlab\ipom"

Write-Host "Repositorio: $repo"
Write-Host "Carpeta Matlab/IPoM: $ipom"

$cmds = @()
$cmds += "cd('$($ipom -replace '\\','/')')"
if ($RebuildHistory) { $cmds += "IPOM_REBUILD_HISTORY = true" }
if ($PdfReports) { $cmds += "IPOM_RUN_REPORT = true" }
$cmds += "run_tpm45_2026"
$batch = ($cmds -join "; ")

matlab -batch $batch

Write-Host "Matlab/IRIS finalizó. Siguientes pasos:"
Write-Host "  Rscript scripts/03_build_ipom_outputs.R"
Write-Host "  python scripts/build_site.py"
Write-Host "  python scripts/validate_site.py"
