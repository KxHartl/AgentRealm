# Data Integrity Check
# usage: .\.ai\scripts\helpers\check-data.ps1 [-Lock]

param (
    [switch]$Lock
)

$rootDir = git rev-parse --show-toplevel 2>$null
if ($LASTEXITCODE -ne 0) { $rootDir = Get-Location }
Set-Location $rootDir

$rawPath = Join-Path $rootDir "data/process/raw"
$manifestPath = Join-Path $rawPath "manifest.sha256"

if (-not (Test-Path $rawPath)) {
    Write-Host "Warning: data/process/raw directory not found. Skipping integrity check." -ForegroundColor Gray
    exit 0
}

function Get-FileHashes {
    Get-ChildItem -Path $rawPath -File -Recurse -Exclude "manifest.sha256" | 
    Get-FileHash -Algorithm SHA256 | 
    ForEach-Object { "$($_.Hash)  $($_.Path.Replace($rawPath + '\', ''))" }
}

if ($Lock) {
    Write-Host "Locking data in $rawPath..." -ForegroundColor Cyan
    Get-FileHashes | Out-File -FilePath $manifestPath -Encoding utf8
    Write-Host "Manifest created at $manifestPath" -ForegroundColor Green
    exit 0
}

if (-not (Test-Path $manifestPath)) {
    Write-Host "Warning: No manifest found in data/process/raw/. Run with -Lock to secure data." -ForegroundColor Yellow
    exit 0
}

Write-Host "Verifying data integrity in data/process/raw/..." -ForegroundColor Cyan
$currentHashes = Get-FileHashes
$storedHashes = Get-Content $manifestPath

$failed = $false
foreach ($hash in $currentHashes) {
    if ($storedHashes -notcontains $hash) {
        Write-Host "INTEGRITY BREACH: $hash" -ForegroundColor Red
        $failed = $true
    }
}

if (-not $failed) {
    Write-Host "Data integrity verified." -ForegroundColor Green
} else {
    Write-Host "CRITICAL: Raw data has been modified! Check AGENTS.md for rules." -ForegroundColor Red
    exit 1
}
