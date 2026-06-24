$ErrorActionPreference = "Stop"

function Find-Rscript {
  $cmd = Get-Command Rscript -ErrorAction SilentlyContinue
  if ($null -ne $cmd) { return $cmd.Source }

  if (Test-Path "C:\Program Files\R") {
    $candidates = Get-ChildItem "C:\Program Files\R" -Recurse -Filter Rscript.exe -ErrorAction SilentlyContinue |
      Sort-Object FullName -Descending |
      Select-Object -ExpandProperty FullName
    if ($candidates.Count -gt 0) { return $candidates[0] }
  }

  throw "No encontré Rscript.exe. Instala R o agrega Rscript al PATH."
}

$repo = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $repo

$RSCRIPT = Find-Rscript
Write-Host "Usando Rscript: $RSCRIPT"

Write-Host "`n1/5 Sincronizando repositorio..."
git pull

Write-Host "`n2/5 Actualizando outputs IMACEC..."
& $RSCRIPT "scripts\01_update_imacec.R"

$projection = Import-Csv "data\processed\imacec_projection.csv"
$target = ([datetime]$projection.Periodo).ToString("yyyy-MM")
$updateDate = ([datetime]$projection.fecha_actualizacion).ToString("yyyy-MM-dd")

Write-Host "`n3/5 Renderizando sitio Quarto sin freeze..."
quarto render --execute

Write-Host "`n4/5 Validando HTML publicado localmente..."
$html = Get-Content "docs\proyectos\imacec.html" -Raw
if ($html -notmatch $target) {
  throw "El HTML generado no contiene el período objetivo $target. Revisa Quarto/freeze/docs."
}
if ($html -notmatch $updateDate) {
  throw "El HTML generado no contiene la fecha de actualización $updateDate. Revisa Quarto/freeze/docs."
}

Write-Host "`n5/5 Estado Git:"
git status

Write-Host "`nListo. Si el estado muestra cambios, sube con:"
Write-Host "git add ."
Write-Host "git commit -m \"Actualiza nowcast IMACEC\""
Write-Host "git push"
