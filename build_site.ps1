param([switch]$Install)
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

$python = Get-Command python -ErrorAction SilentlyContinue
if ($null -eq $python) {
  $python = Get-Command py -ErrorAction SilentlyContinue
  if ($null -eq $python) { throw "No encontré Python. Instala Python 3.11 o superior." }
  $pythonArgs = @('-3')
} else {
  $pythonArgs = @()
}

if ($Install) {
  & $python.Source @pythonArgs -m pip install -r requirements-site.txt
}
& $python.Source @pythonArgs scripts/build_site.py
& $python.Source @pythonArgs scripts/validate_site.py
Write-Host "Sitio listo en docs/." -ForegroundColor Green
