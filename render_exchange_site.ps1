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

    $candidates = Get-ChildItem "C:\Program Files\R" -Directory -ErrorAction SilentlyContinue |
        Sort-Object Name -Descending |
        ForEach-Object { Join-Path $_.FullName "bin\Rscript.exe" } |
        Where-Object { Test-Path $_ }

    if ($candidates -and $candidates.Count -gt 0) { return $candidates[0] }
    throw "No encontré Rscript. Instala R o agrega Rscript al PATH."
}

function Find-Quarto {
    $cmd = Get-Command quarto -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    $candidate = "C:\Program Files\Quarto\bin\quarto.cmd"
    if (Test-Path $candidate) { return $candidate }
    throw "No encontré Quarto. Instala Quarto o agrega quarto al PATH."
}

function Ensure-Dir($Path) {
    if (!(Test-Path $Path)) {
        New-Item -ItemType Directory -Force -Path $Path | Out-Null
    }
}

function Convert-PngToJpg($Source, $Target) {
    Add-Type -AssemblyName System.Drawing
    $img = [System.Drawing.Image]::FromFile($Source)
    try {
        $jpgCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" }
        $encoder = [System.Drawing.Imaging.Encoder]::Quality
        $params = New-Object System.Drawing.Imaging.EncoderParameters(1)
        $params.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter($encoder, [int64]88)
        $img.Save($Target, $jpgCodec, $params)
    }
    finally {
        $img.Dispose()
    }
}

function Remove-OldPublicPages {
    $oldPublic = @(
        "docs\proyectos\imacec.html",
        "docs\proyectos\ipom-iris.html",
        "docs\proyectos\transmision-tpm.html",
        "docs\proyectos\estres-externo.html",
        "docs\proyectos\curva-rendimiento.html",
        "docs\proyectos\transmision-tpm_files"
    )

    foreach ($rel in $oldPublic) {
        $p = Join-Path $Repo $rel
        if (Test-Path $p) {
            Remove-Item $p -Recurse -Force
            Write-Host "Eliminado de docs público: $rel"
        }
    }
}

if (!(Test-Path (Join-Path $Repo "_quarto.yml"))) {
    throw "Ejecuta este script desde la raíz del repo Economics."
}

if (!$NoModel) {
    $Rscript = Find-Rscript
    & $Rscript "scripts\exchange\render_exchange_model.R" $Repo
}

if (!$NoModel) {
    $ModelDir = Join-Path $Repo "modelos\exchange"
    $Graficos = Join-Path $ModelDir "Graficos"
    $Pdf = Join-Path $ModelDir "exchange_report.pdf"

    if (!(Test-Path $Graficos)) {
        throw "No existe la carpeta de gráficos: $Graficos. Renderiza el modelo o revisa errores de R."
    }
    if (!(Test-Path $Pdf)) {
        throw "No existe el PDF del modelo: $Pdf. Renderiza el modelo o revisa errores de R/LaTeX."
    }

    $AssetImg = Join-Path $Repo "assets\img\exchange"
    $AssetFiles = Join-Path $Repo "assets\files"
    Ensure-Dir $AssetImg
    Ensure-Dir $AssetFiles

    Copy-Item $Pdf (Join-Path $AssetFiles "exchange_report.pdf") -Force

    $needed = @(
        "fx_residuals_zscores_from2018.png",
        "y10_residuals_zscores_from2018.png",
        "stress_fx_y10_CLP.png",
        "stress_fx_y10_BRL.png",
        "stress_fx_y10_MXN.png",
        "stress_fx_y10_PEN.png",
        "stress_fx_y10_COP.png",
        "second_stage_fx_y10_CLP.png",
        "second_stage_fx_y10_BRL.png",
        "second_stage_fx_y10_MXN.png",
        "second_stage_fx_y10_PEN.png",
        "second_stage_fx_y10_COP.png"
    )

    foreach ($file in $needed) {
        $src = Join-Path $Graficos $file
        if (Test-Path $src) {
            $jpgName = [System.IO.Path]::ChangeExtension($file, ".jpg")
            Convert-PngToJpg $src (Join-Path $AssetImg $jpgName)
            Write-Host "OK gráfico web: $jpgName"
        }
        else {
            Write-Warning "No encontré $file en $Graficos"
        }
    }
}

Remove-OldPublicPages

if (!$NoQuarto) {
    $Quarto = Find-Quarto
    & $Quarto render
}

Remove-OldPublicPages

Write-Host ""
Write-Host "Listo: modelo + assets + sitio GitHub Pages actualizados."
Write-Host "Ahora revisa con: git status"
Write-Host "Y sube con: git add . ; git commit -m 'Publish ExchangeReg with BIS CPI' ; git push"
