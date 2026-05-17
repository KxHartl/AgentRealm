<#
.SYNOPSIS
    Checks and installs missing LaTeX packages required by FSB templates.
.DESCRIPTION
    Reads ..ai/templates/latex-requirements.txt and verifies each package
    is installed via MiKTeX. Missing packages are auto-installed.
.NOTES
    Requires MiKTeX with mpm (MiKTeX Package Manager) on PATH.
#>

param(
    [switch]$DryRun,
    [string]$RequirementsFile = ""
)

$ErrorActionPreference = "Continue"

# Find requirements file
if (-not $RequirementsFile) {
    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $RepoRoot = (Get-Item "$ScriptDir\..\..\..").FullName
    $RequirementsFile = Join-Path $RepoRoot ".ai/templates/latex-requirements.txt"
}

if (-not (Test-Path $RequirementsFile)) {
    Write-Error "Requirements file not found: $RequirementsFile"
    exit 1
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " LaTeX Package Requirements Checker" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if pdflatex is available
$pdflatex = Get-Command pdflatex -ErrorAction SilentlyContinue
if (-not $pdflatex) {
    Write-Host "[ERROR] pdflatex not found. Install MiKTeX first: https://miktex.org/" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] pdflatex found: $($pdflatex.Source)" -ForegroundColor Green

# Check if mpm (MiKTeX Package Manager) is available
$mpm = Get-Command mpm -ErrorAction SilentlyContinue
if (-not $mpm) {
    # Try miktex-pm as alternative
    $mpm = Get-Command miktex -ErrorAction SilentlyContinue
    if (-not $mpm) {
        Write-Host "[WARN] MiKTeX package manager (mpm/miktex) not found on PATH." -ForegroundColor Yellow
        Write-Host "       MiKTeX will auto-install packages on first use (if configured)." -ForegroundColor Yellow
        Write-Host "       To enable: MiKTeX Console > Settings > 'Always install missing packages'" -ForegroundColor Yellow
    }
}

# Parse requirements file
$packages = Get-Content $RequirementsFile | ForEach-Object {
    $line = $_.Trim()
    # Skip comments and empty lines
    if ($line -and -not $line.StartsWith("#")) {
        # Remove inline comments
        $pkg = ($line -split '#')[0].Trim()
        if ($pkg) { $pkg }
    }
}

Write-Host ""
Write-Host "Checking $($packages.Count) packages from: $RequirementsFile" -ForegroundColor Cyan
Write-Host ""

$missing = @()
$installed = @()

foreach ($pkg in $packages) {
    # Create a minimal .tex file that loads the package
    $testFile = [System.IO.Path]::GetTempFileName() -replace '\.tmp$', '.tex'
    $testDir = Split-Path $testFile
    $testBase = [System.IO.Path]::GetFileNameWithoutExtension($testFile)

    # Handle babel-croatian specially (it's a babel option, not a standalone package)
    if ($pkg -eq "babel-croatian") {
        $texContent = "\documentclass{article}`n\usepackage[croatian]{babel}`n\begin{document}`ntest`n\end{document}"
    } elseif ($pkg -eq "tikz") {
        $texContent = "\documentclass{article}`n\usepackage{tikz}`n\begin{document}`ntest`n\end{document}"
    } elseif ($pkg -eq "pgfplots") {
        $texContent = "\documentclass{article}`n\usepackage{pgfplots}`n\pgfplotsset{compat=1.18}`n\begin{document}`ntest`n\end{document}"
    } else {
        $texContent = "\documentclass{article}`n\usepackage{$pkg}`n\begin{document}`ntest`n\end{document}"
    }

    Set-Content -Path $testFile -Value $texContent -Encoding UTF8

    $result = & pdflatex -interaction=nonstopmode -output-directory=$testDir $testFile 2>$null | Out-String
    $exitCode = $LASTEXITCODE

    if ($result -match "File.*not found" -or $result -match "Emergency stop" -or $exitCode -ne 0) {
        Write-Host "  [MISSING] $pkg" -ForegroundColor Red
        $missing += $pkg
    } else {
        Write-Host "  [OK]      $pkg" -ForegroundColor Green
        $installed += $pkg
    }

    # Cleanup
    Remove-Item "$testDir\$testBase.*" -Force -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Results: $($installed.Count) installed, $($missing.Count) missing" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if ($missing.Count -gt 0) {
    Write-Host ""
    Write-Host "Missing packages:" -ForegroundColor Yellow
    $missing | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }

    if (-not $DryRun) {
        Write-Host ""
        Write-Host "Attempting to install missing packages via MiKTeX..." -ForegroundColor Cyan

        foreach ($pkg in $missing) {
            Write-Host "  Installing: $pkg" -ForegroundColor Yellow
            try {
                if ($mpm) {
                    & mpm --install $pkg 2>&1 | Out-Null
                } else {
                    # Fallback: compile a file that uses the package, MiKTeX auto-installs
                    $testFile = [System.IO.Path]::GetTempFileName() -replace '\.tmp$', '.tex'
                    $testDir = Split-Path $testFile
                    Set-Content -Path $testFile -Value "\documentclass{article}`n\usepackage{$pkg}`n\begin{document}`ntest`n\end{document}" -Encoding UTF8
                    & pdflatex -interaction=nonstopmode -output-directory=$testDir $testFile 2>&1 | Out-Null
                    Remove-Item "$testDir\$([System.IO.Path]::GetFileNameWithoutExtension($testFile)).*" -Force -ErrorAction SilentlyContinue
                }
                Write-Host "    [INSTALLED] $pkg" -ForegroundColor Green
            } catch {
                Write-Host "    [FAILED] $pkg - $_" -ForegroundColor Red
            }
        }
    } else {
        Write-Host ""
        Write-Host "(Dry run - no packages installed. Run without -DryRun to install.)" -ForegroundColor Yellow
    }
} else {
    Write-Host ""
    Write-Host "All packages are installed! Templates are ready to compile." -ForegroundColor Green
}
