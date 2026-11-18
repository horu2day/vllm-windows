<#
.SYNOPSIS
    Downloads the TranslateGemma GGUF weights into ./models/translate.

.DESCRIPTION
    The container looks for the weights at
        /root/.cache/translate/models/translategemma-<size>-it-Q<bits>.gguf
    which docker-compose.translategemma.yml maps to ./models/translate.
    Pre-downloading here avoids a cold-start download inside the container.

    Default is 12b / Q4_K_M (7.3 GB) - the largest TranslateGemma that fits
    an RTX 3060 12GB alongside its KV cache.

.EXAMPLE
    pwsh ./scripts/download-translategemma.ps1
    pwsh ./scripts/download-translategemma.ps1 -Size 4b -Bits 4
#>
[CmdletBinding()]
param(
    [ValidateSet('4b', '12b', '27b')]
    [string]$Size = '12b',

    [ValidateSet(4, 8)]
    [int]$Bits = 4,

    [string]$HfEndpoint = 'https://huggingface.co',

    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$quantFile = if ($Bits -eq 4) { 'Q4_K_M' } else { 'Q8_0' }
$repo      = "mradermacher/translategemma-$Size-it-GGUF"
$remote    = "translategemma-$Size-it.$quantFile.gguf"
$url       = "$HfEndpoint/$repo/resolve/main/$remote`?download=true"

$root   = Split-Path -Parent $PSScriptRoot
$outDir = Join-Path $root 'models\translate'
$outFile = Join-Path $outDir "translategemma-$Size-it-Q$Bits.gguf"

if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }

if ((Test-Path $outFile) -and -not $Force) {
    $sizeGb = [math]::Round((Get-Item $outFile).Length / 1GB, 2)
    Write-Host "Already present: $outFile ($sizeGb GB). Use -Force to re-download." -ForegroundColor Green
    exit 0
}
if ($Force -and (Test-Path $outFile)) { Remove-Item $outFile -Force }

Write-Host "Repo : $repo"
Write-Host "File : $remote"
Write-Host "Dest : $outFile"
Write-Host ''

# curl.exe ships with Windows 10+ and resumes interrupted transfers with -C -
& curl.exe -L -C - --retry 5 --retry-delay 5 --progress-bar -o "$outFile" "$url"
if ($LASTEXITCODE -ne 0) { throw "Download failed (curl exit $LASTEXITCODE). Re-run to resume." }

$sizeGb = [math]::Round((Get-Item $outFile).Length / 1GB, 2)
Write-Host ""
Write-Host "Done: $outFile ($sizeGb GB)" -ForegroundColor Green
