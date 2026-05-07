# Minimal data integrity check (extend as needed)
Write-Host "[Data] Running lightweight data/raw checks..."
$rawPath = Join-Path (Get-Location) 'data\raw'
if (-not (Test-Path $rawPath)) {
    Write-Host "[Data] No data/raw directory found. Skipping detailed checks." -ForegroundColor Yellow
    exit 0
}

$files = Get-ChildItem -Path $rawPath -Recurse -File -ErrorAction SilentlyContinue
if (-not $files) {
    Write-Host "[Data] data/raw is empty. Add source files or a .gitkeep." -ForegroundColor Yellow
    exit 0
}

# Example check: ensure no .xlsx files in raw (policy)
$bad = $files | Where-Object { $_.Extension -ieq '.xlsx' }
if ($bad) {
    Write-Host "[Data] Found disallowed file types in data/raw: " -ForegroundColor Red
    $bad | ForEach-Object { Write-Host $_.FullName }
    exit 2
}

Write-Host "[Data] Basic checks passed. Extend check-data.ps1 for stricter policies." -ForegroundColor Green
exit 0
