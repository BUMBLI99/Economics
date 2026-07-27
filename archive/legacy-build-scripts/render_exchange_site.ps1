param(
    [switch]$NoModel,
    [switch]$NoQuarto
)

$ErrorActionPreference = "Stop"
$Repo = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $Repo

function Find-Rscript {
    $cmd = Get-Command Rscript -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    $candidates = @(
        Get-ChildItem "C:\Program Files\R" -Directory -ErrorAction SilentlyContinue |
            Sort-Object Name -Descending |
            ForEach-Object { Join-Path $_.FullName "bin\Rscript.exe" } |
            Where-Object { Test-Path $_ }
    )

    if ($candidates) { return ($candidates | Select-Object -First 1) }
    throw "No encontre Rscript. Instala R o agrega Rscript al PATH."
}

function Find-Quarto([switch]$Optional) {
    $cmd = Get-Command quarto -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    $candidates = @(
        "C:\Program Files\Quarto\bin\quarto.cmd",
        "C:\Program Files\Quarto\bin\quarto.exe",
        "$env:LOCALAPPDATA\Programs\Quarto\bin\quarto.cmd",
        "$env:LOCALAPPDATA\Programs\Quarto\bin\quarto.exe"
    ) | Where-Object { $_ -and (Test-Path $_) }

    if ($candidates) { return ($candidates | Select-Object -First 1) }
    if ($Optional) { return $null }
    throw "No encontre Quarto. Instala Quarto o agrega quarto al PATH."
}

function Ensure-Dir($Path) {
    if (!(Test-Path $Path)) {
        New-Item -ItemType Directory -Force -Path $Path | Out-Null
    }
}

function Remove-OldChileStressPublicPage {
    $oldPublic = @(
        "docs\proyectos\estres-externo.html",
        "docs\proyectos\estres-externo_files"
    )
    foreach ($rel in $oldPublic) {
        $p = Join-Path $Repo $rel
        if (Test-Path $p) {
            Remove-Item $p -Recurse -Force
            Write-Host "Ocultado de docs publico: $rel"
        }
    }
}

function Copy-Assets-To-Docs {
    $pairs = @(
        @{ Source = "assets\img\exchange"; Target = "docs\assets\img\exchange" },
        @{ Source = "assets\files";        Target = "docs\assets\files" },
        @{ Source = "data\processed\exchange"; Target = "docs\data\processed\exchange" }
    )

    foreach ($pair in $pairs) {
        $src = Join-Path $Repo $pair.Source
        $dst = Join-Path $Repo $pair.Target
        if (Test-Path $src) {
            Ensure-Dir $dst
            Copy-Item (Join-Path $src "*") $dst -Recurse -Force
        }
    }
}

if (!(Test-Path (Join-Path $Repo "_quarto.yml"))) {
    throw "Ejecuta este script desde la raiz del repo Economics."
}

if (!$NoModel) {
    $Rscript = Find-Rscript
    Write-Host "Actualizando outputs ExchangeReg: datos, modelos y graficos web..."
    & $Rscript "scripts\exchange\build_exchange_outputs.R" $Repo
}
else {
    Write-Host "Saltando modelo: se usan los outputs ya existentes en data/processed/exchange y assets/img/exchange."
}

Remove-OldChileStressPublicPage
Copy-Assets-To-Docs

if (!$NoQuarto) {
    $Quarto = Find-Quarto
    Write-Host "Renderizando sitio Quarto..."
    & $Quarto render
    Copy-Assets-To-Docs
}

Remove-OldChileStressPublicPage

Write-Host ""
Write-Host "Listo. Revisa con: git status"
