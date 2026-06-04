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

    if ($candidates.Count -gt 0) { return ($candidates | Select-Object -First 1) }
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

    if ($candidates.Count -gt 0) { return ($candidates | Select-Object -First 1) }
    if ($Optional) { return $null }
    throw "No encontre Quarto. Instala Quarto o agrega quarto al PATH."
}

function Set-PandocForR {
    if ($env:RSTUDIO_PANDOC -and (Test-Path (Join-Path $env:RSTUDIO_PANDOC "pandoc.exe"))) {
        Write-Host "Pandoc para R: $env:RSTUDIO_PANDOC"
        return
    }

    $quarto = Find-Quarto -Optional
    $dirs = @()
    if ($quarto) {
        $qbin = Split-Path -Parent $quarto
        $dirs += (Join-Path $qbin "tools")
    }
    $dirs += @(
        "C:\Program Files\Quarto\bin\tools",
        "$env:LOCALAPPDATA\Programs\Quarto\bin\tools"
    )

    foreach ($d in $dirs) {
        if ($d -and (Test-Path (Join-Path $d "pandoc.exe"))) {
            $env:RSTUDIO_PANDOC = $d
            Write-Host "Pandoc para R: $env:RSTUDIO_PANDOC"
            return
        }
    }

    $pandoc = Get-Command pandoc -ErrorAction SilentlyContinue
    if ($pandoc) {
        $env:RSTUDIO_PANDOC = Split-Path -Parent $pandoc.Source
        Write-Host "Pandoc para R: $env:RSTUDIO_PANDOC"
        return
    }

    Write-Warning "No encontre pandoc para R. Si quieres correr el modelo PDF, instala Quarto o abre desde RStudio. Para publicar el sitio con outputs ya incluidos usa: .\render_exchange_site.ps1 -NoModel"
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
    $srcImg = Join-Path $Repo "assets\img\exchange"
    $dstImg = Join-Path $Repo "docs\assets\img\exchange"
    $srcFiles = Join-Path $Repo "assets\files"
    $dstFiles = Join-Path $Repo "docs\assets\files"

    if (Test-Path $srcImg) {
        Ensure-Dir $dstImg
        Copy-Item (Join-Path $srcImg "*") $dstImg -Recurse -Force
    }
    if (Test-Path (Join-Path $srcFiles "exchange_report.pdf")) {
        Ensure-Dir $dstFiles
        Copy-Item (Join-Path $srcFiles "exchange_report.pdf") (Join-Path $dstFiles "exchange_report.pdf") -Force
    }
}

if (!(Test-Path (Join-Path $Repo "_quarto.yml"))) {
    throw "Ejecuta este script desde la raiz del repo Economics."
}

if (!$NoModel) {
    Set-PandocForR
    $Rscript = Find-Rscript
    Write-Host "Renderizando modelo Exchange con CPI BIS..."
    & $Rscript "scripts\exchange\render_exchange_model.R" $Repo

    $ModelDir = Join-Path $Repo "modelos\exchange"
    $Graficos = Join-Path $ModelDir "Graficos"
    $Pdf = Join-Path $ModelDir "exchange_report.pdf"

    if (!(Test-Path $Graficos)) {
        throw "No existe la carpeta de graficos: $Graficos. Si solo quieres publicar con los outputs incluidos, ejecuta: .\render_exchange_site.ps1 -NoModel"
    }
    if (!(Test-Path $Pdf)) {
        throw "No existe el PDF del modelo: $Pdf. Si solo quieres publicar con los outputs incluidos, ejecuta: .\render_exchange_site.ps1 -NoModel"
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
            Write-Host "OK grafico web: $jpgName"
        }
        else {
            Write-Warning "No encontre $file en $Graficos"
        }
    }
}
else {
    Write-Host "Saltando modelo: se usan los outputs ya incluidos en assets/."
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
