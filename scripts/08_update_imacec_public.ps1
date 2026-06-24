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

Write-Host "`n1/4 Actualizando outputs IMACEC..."
& $RSCRIPT "scripts\01_update_imacec.R"

$projection = Import-Csv "data\processed\imacec_projection.csv"
$target = ([datetime]$projection.Periodo).ToString("yyyy-MM")
$updateDate = ([datetime]$projection.fecha_actualizacion).ToString("yyyy-MM-dd")

Write-Host "`n2/4 Renderizando sitio Quarto público..."
quarto render --execute

Write-Host "`n3/4 Limpiando HTML internos residuales..."
& scripts\00_clean_public_docs.bat

Write-Host "`n4/4 Validando HTML publicado localmente..."
$htmlPath = "docs\proyectos\imacec.html"
if (!(Test-Path $htmlPath)) {
  throw "No se generó $htmlPath. Revisa _quarto.yml y el render."
}

$html = Get-Content $htmlPath -Raw
if ($html -notmatch $target) {
  throw "El HTML generado no contiene el período objetivo $target. Revisa Quarto/freeze/docs."
}
if ($html -notmatch $updateDate) {
  throw "El HTML generado no contiene la fecha de actualización $updateDate. Revisa Quarto/freeze/docs."
}
if (Test-Path "docs\matlab\ipom\src\r\archive_exploratory\Data_IPOM_exploratory.html") {
  throw "Se renderizó un Rmd interno que no debe ser público. Revisa project.render en _quarto.yml."
}

Write-Host "`nListo. Si el estado muestra cambios, sube con:"
Write-Host "git add ."
Write-Host "git commit -m \"Actualiza nowcast IMACEC\""
Write-Host "git push"
Write-Host ""
git status
