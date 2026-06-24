# Render de emergencia: NO actualiza datos, solo reconstruye el sitio público.
# Uso:
#   powershell -ExecutionPolicy Bypass -File scripts\09_rebuild_public_site.ps1

$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $repo

Write-Host "Renderizando solo páginas públicas definidas en _quarto.yml..."
quarto render --execute

Write-Host "Limpiando HTML internos residuales..."
& scripts\00_clean_public_docs.bat

if (Test-Path "docs\matlab\ipom\src\r\archive_exploratory\Data_IPOM_exploratory.html") {
  throw "Se renderizó Data_IPOM_exploratory.html. Revisa project.render en _quarto.yml."
}

Write-Host "Listo. Estado Git:"
git status
