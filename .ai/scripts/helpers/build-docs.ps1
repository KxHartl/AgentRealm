# Unified Documentation Build Script
# usage: .\build-docs.ps1 [-Clean]

param (
    [switch]$Clean
)

$rootDir = git rev-parse --show-toplevel 2>$null
if ($LASTEXITCODE -ne 0) { $rootDir = Get-Location }
Set-Location $rootDir

Write-Host "--- 📚 Building Documentation ---" -ForegroundColor Cyan

$distDir = Join-Path $rootDir "dist"
if (-not (Test-Path $distDir)) { New-Item -ItemType Directory -Path $distDir }

# 1. Build LaTeX documents
$texFiles = Get-ChildItem -Path "docs" -Filter "*.tex" -Recurse | Where-Object { $_.FullName -notmatch "templates" }

foreach ($file in $texFiles) {
    Write-Host "[LaTeX] Building $($file.Name)..." -ForegroundColor Yellow
    $outDir = Join-Path $file.DirectoryName "build"
    
    # Run latexmk
    latexmk -pdf -interaction=nonstopmode -shell-escape -outdir=$outDir $file.FullName
    
    if ($LASTEXITCODE -eq 0) {
        $pdfName = $file.BaseName + ".pdf"
        $generatedPdf = Join-Path $outDir $pdfName
        if (Test-Path $generatedPdf) {
            Copy-Item $generatedPdf -Destination (Join-Path $distDir $pdfName) -Force
            Write-Host "✅ Success: $pdfName moved to dist/" -ForegroundColor Green
        }
    } else {
        Write-Host "❌ Failed to build $($file.Name)" -ForegroundColor Red
    }
}

# 2. Build Markdown documents with Pandoc
$mdFiles = Get-ChildItem -Path "docs" -Filter "*.md" -Recurse | Where-Object { $_.FullName -notmatch "templates" }

foreach ($file in $mdFiles) {
    if ($file.Name -eq "README.md") { continue }
    
    Write-Host "[Pandoc] Converting $($file.Name) to PDF..." -ForegroundColor Yellow
    $pdfName = $file.BaseName + ".pdf"
    $outputPath = Join-Path $distDir $pdfName
    
    # Custom FSB Seminar LaTeX compilation if inside seminar and helper exists
    $seminarTemplate = Join-Path $rootDir ".ai/templates/fsb-seminar/latex/seminar.tex"
    $compilerScript = Join-Path $rootDir ".ai/scripts/helpers/compile_seminar.py"
    
    if ($file.FullName -match "seminar" -and (Test-Path $seminarTemplate) -and (Test-Path $compilerScript)) {
        Write-Host "FSB Seminar detected! Utilizing Auto-LaTeX compiler with templates..." -ForegroundColor Green
        python $compilerScript $file.FullName $seminarTemplate $outputPath
    } else {
        pandoc $file.FullName -o $outputPath --pdf-engine=pdflatex
    }
    
    if ($LASTEXITCODE -eq 0 -or (Test-Path $outputPath)) {
        Write-Host "✅ Success: $pdfName generated in dist/" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to convert $($file.Name)" -ForegroundColor Red
    }
}

if ($Clean) {
    Write-Host "Cleaning up build directories..." -ForegroundColor Gray
    Get-ChildItem -Path "docs" -Directory -Filter "build" -Recurse | Remove-Item -Recurse -Force
}

Write-Host "--- ✨ Build Finished ---" -ForegroundColor Cyan
