# Enhanced data integrity checks
# - Require data/raw/README.md describing sources
# - Fail on disallowed extensions (e.g., .xlsx)
# - Warn if files larger than 100MB
# - Detect duplicate filenames (case-insensitive)

Write-Host "[Data] Running enhanced data/raw checks..."
$root = Get-Location
$rawPath = Join-Path $root 'data\raw'
if (-not (Test-Path $rawPath)) {
    Write-Host "[Data] No data/raw directory found. Skipping detailed checks." -ForegroundColor Yellow
    exit 0
}

$errors = @()
$warnings = @()

# 1. README presence
if (-not (Test-Path (Join-Path $rawPath 'README.md'))) {
    $warnings += "Missing data/raw/README.md describing data sources and licenses."
}

# 2. Disallowed extensions
$disallowed = @('.xlsx', '.exe', '.dll')
$files = Get-ChildItem -Path $rawPath -Recurse -File -ErrorAction SilentlyContinue
foreach ($f in $files) {
    if ($disallowed -contains $f.Extension.ToLower()) {
        $errors += "Disallowed file type: $($f.FullName)"
    }
    if ($f.Length -gt 100MB) {
        $warnings += "Large file (>100MB): $($f.FullName) Size=$([math]::Round($f.Length/1MB,2))MB"
    }
}

# 3. Duplicate filenames (case-insensitive)
$nameGroups = $files | Group-Object { $_.Name.ToLower() } | Where-Object { $_.Count -gt 1 }
foreach ($g in $nameGroups) {
    $errors += "Duplicate filenames detected: $($g.Name) - occurrences: $($g.Count)"
}

# Report
if ($warnings.Count -gt 0) { Write-Host "[Data] Warnings:" -ForegroundColor Yellow; $warnings | ForEach-Object { Write-Host " - $_" } }
if ($errors.Count -gt 0) { Write-Host "[Data] Errors:" -ForegroundColor Red; $errors | ForEach-Object { Write-Host " - $_" }; exit 2 }

Write-Host "[Data] Enhanced checks passed." -ForegroundColor Green
exit 0
