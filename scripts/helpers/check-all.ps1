param(
    [string]$OutputLog
)

# Unified Sanity Check with logging and exit codes

$rootDir = git rev-parse --show-toplevel 2>$null
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($rootDir)) {
    $rootDir = Get-Location
}
Set-Location $rootDir

$transcript = $null
if ($OutputLog) {
    $logDir = Split-Path $OutputLog -Parent
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
    Start-Transcript -Path $OutputLog -Force | Out-Null
    $transcript = $OutputLog
}

Write-Host "--- 🔍 Starting Unified Sanity Check ---" -ForegroundColor Cyan
$exitCode = 0

# 1. Requirements
Write-Host "[Requirements] Checking manifest..." -ForegroundColor Yellow
# Prefer PowerShell check if available, otherwise try shell script
if (Test-Path ".\scripts\helpers\check-requirements.ps1") {
    & .\scripts\helpers\check-requirements.ps1 *> $null
} elseif (Test-Path ".\scripts\helpers\check-requirements.sh") {
    # Run bash if available
    if (Get-Command bash -ErrorAction SilentlyContinue) {
        bash -lc "./scripts/helpers/check-requirements.sh" *> $null
    } else {
        Write-Host "No bash available to run shell requirements check; skipping." -ForegroundColor Yellow
    }
} else {
    Write-Host "No requirements checker found; skipping." -ForegroundColor Gray
}
$reqExit = $LASTEXITCODE
if ($reqExit -ne 0) { Write-Host "Requirements check reported issues (exit $reqExit)" -ForegroundColor Yellow; $exitCode = $exitCode -bor 1 }

# 2. Python Checks
$pythonFiles = Get-ChildItem -Path . -Filter "*.py" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch "\\.venv|node_modules|\\.git|\\.agents" }
if ($pythonFiles) {
    Write-Host "[Python] Files detected. Running ruff if available..." -ForegroundColor Yellow
    if (Get-Command ruff -ErrorAction SilentlyContinue) {
        ruff check .
        if ($LASTEXITCODE -ne 0) { $exitCode = $exitCode -bor 2 }
    } else {
        Write-Host "Warning: ruff not found. Skipping Python linting." -ForegroundColor Gray
    }
}

# 3. LaTeX Checks
$texFiles = Get-ChildItem -Path . -Filter "*.tex" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch "\\.venv|node_modules|\\.git|\\.agents" }
if ($texFiles) {
    Write-Host "[LaTeX] Files detected. Running chktex if available..." -ForegroundColor Yellow
    if (Get-Command chktex -ErrorAction SilentlyContinue) {
        chktex -q -l .chktexrc .
        if ($LASTEXITCODE -ne 0) { $exitCode = $exitCode -bor 4 }
    } else {
        Write-Host "Warning: chktex not found. Skipping LaTeX linting." -ForegroundColor Gray
    }
}

# 4. Node.js Checks
if (Test-Path "package.json") {
    Write-Host "[Node.js] package.json detected. Checking for lint script..." -ForegroundColor Yellow
    $packageJson = Get-Content "package.json" | ConvertFrom-Json
    if ($packageJson.scripts.lint) {
        npm run lint
        if ($LASTEXITCODE -ne 0) { $exitCode = $exitCode -bor 8 }
    } else {
        Write-Host "No lint script found in package.json." -ForegroundColor Gray
    }
}

# 5. C++ Checks
if (Test-Path "CMakeLists.txt") {
    Write-Host "[C++] CMakeLists.txt detected." -ForegroundColor Yellow
    Write-Host "Tip: Run 'cmake -S . -B build' and 'cmake --build build' to verify build." -ForegroundColor Gray
}

# 6. Data Integrity
Write-Host "[Data] Verifying raw data integrity..." -ForegroundColor Yellow
if (Test-Path ".\scripts\helpers\check-data.ps1") {
    & .\scripts\helpers\check-data.ps1
    if ($LASTEXITCODE -ne 0) { $exitCode = $exitCode -bor 16 }
} else {
    Write-Host "No check-data.ps1 found; skipping data checks." -ForegroundColor Gray
}

Write-Host "--- ✅ Sanity Check Finished ---" -ForegroundColor Cyan

if ($transcript) { Stop-Transcript | Out-Null }

exit $exitCode
