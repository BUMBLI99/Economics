# Reconstruye el sitio con los últimos outputs procesados, sin recalcular modelos.
# Uso desde la raíz:
#   powershell -ExecutionPolicy Bypass -File scripts\09_rebuild_public_site.ps1

$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent $PSScriptRoot
Set-Location $repo

function Find-Python {
  $python = Get-Command python -ErrorAction SilentlyContinue
  if ($null -ne $python) { return @{ Command = $python.Source; Args = @() } }
  $py = Get-Command py -ErrorAction SilentlyContinue
  if ($null -ne $py) { return @{ Command = $py.Source; Args = @('-3') } }
  throw "No encontré Python. Instala Python 3.11 o superior."
}

$py = Find-Python
& $py.Command @($py.Args) scripts/build_site.py
& $py.Command @($py.Args) scripts/validate_site.py
Write-Host "Sitio reconstruido y validado en docs/." -ForegroundColor Green
git status --short
