# Unified Sanity Check
# Detects project content and runs relevant quality checks.

$rootDir = git rev-parse --show-toplevel
Set-Location $rootDir

Write-Host "--- 🔍 Starting Unified Sanity Check ---" -ForegroundColor Cyan

# 1. Python Checks
$pythonFiles = Get-ChildItem -Path . -Filter "*.py" -Recurse -Exclude ".venv", "node_modules", ".git", ".agents"
if ($pythonFiles) {
    Write-Host "[Python] Files detected. Running ruff..." -ForegroundColor Yellow
    if (Get-Command ruff -ErrorAction SilentlyContinue) {
        ruff check .
        ruff format --check .
    } else {
        Write-Host "Warning: ruff not found. Skipping Python linting." -ForegroundColor Gray
    }
}

# 2. LaTeX Checks
$texFiles = Get-ChildItem -Path . -Filter "*.tex" -Recurse -Exclude ".venv", "node_modules", ".git", ".agents"
if ($texFiles) {
    Write-Host "[LaTeX] Files detected. Running chktex..." -ForegroundColor Yellow
    if (Get-Command chktex -ErrorAction SilentlyContinue) {
        chktex -q -l .chktexrc .
    } else {
        Write-Host "Warning: chktex not found. Skipping LaTeX linting." -ForegroundColor Gray
    }
}

# 3. Node.js Checks
if (Test-Path "package.json") {
    Write-Host "[Node.js] package.json detected. Checking for lint script..." -ForegroundColor Yellow
    $packageJson = Get-Content "package.json" | ConvertFrom-Json
    if ($packageJson.scripts.lint) {
        npm run lint
    } else {
        Write-Host "No lint script found in package.json." -ForegroundColor Gray
    }
}

# 4. C++ Checks
if (Test-Path "CMakeLists.txt") {
    Write-Host "[C++] CMakeLists.txt detected." -ForegroundColor Yellow
    Write-Host "Tip: Run 'cmake -S . -B build' and 'cmake --build build' to verify build." -ForegroundColor Gray
}

Write-Host "--- ✅ Sanity Check Finished ---" -ForegroundColor Cyan
