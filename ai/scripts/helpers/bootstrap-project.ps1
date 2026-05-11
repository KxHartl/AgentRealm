param (
    [string]$name,
    [string]$ide = "vscode",
    [ValidateSet("none", "cloud", "local")]
    [string]$rag = "none"
)

function Show-Usage {
    Write-Host "Usage: .\ai\scripts\helpers\bootstrap-project.ps1 -name <project-name> [-ide <vscode|antigravity>] [-rag <none|cloud|local>]"
    Write-Host ""
    Write-Host "RAG Modes:"
    Write-Host "  none   (default) No RAG. Zero Python overhead."
    Write-Host "  cloud  Gemini API embeddings. ~200 MB footprint. Requires GOOGLE_API_KEY."
    Write-Host "  local  Local sentence-transformers model. ~1.2 GB footprint. Works offline."
}

if (-not $name) {
    Show-Usage
    exit 1
}

$requirementsManifest = "ai/config/requirements.list"

# Update ai/config/project.yaml
(Get-Content ai/config/project.yaml) -replace '^name: .*', "name: `"$name`"" | Set-Content ai/config/project.yaml
(Get-Content ai/config/project.yaml) -replace '^default_ide: .*', "default_ide: `"$ide`" # vscode | antigravity" | Set-Content ai/config/project.yaml
(Get-Content ai/config/project.yaml) -replace '^rag_mode: .*', "rag_mode: `"$rag`" # none | cloud | local" | Set-Content ai/config/project.yaml

# Update STATE.md
(Get-Content STATE.md) -replace '^- Name: .*', "- Name: $name" | Set-Content STATE.md

if (-not (Select-String -Path ai/config/project.yaml -Pattern '^  requirements:')) {
    Add-Content -Path ai/config/project.yaml -Value "`n  requirements: `"$requirementsManifest`""
}

if (-not (Select-String -Path STATE.md -Pattern '## Requirements')) {
    $requirementsBlock = @"

## Requirements

- Manifest: ai/config/requirements.list
- Check command: ai/scripts/helpers/check-requirements.ps1
- Installation status: _Not checked yet._
"@
    Add-Content -Path STATE.md -Value $requirementsBlock
}

if (-not (Test-Path ai/worktrees)) {
    New-Item -ItemType Directory -Path ai/worktrees
}

# 1. Check and install requirements
Write-Host "Verifying project requirements..." -ForegroundColor Cyan
.\ai\scripts\helpers\check-requirements.ps1 -Install
if ($LASTEXITCODE -ne 0) {
    Write-Host "Warning: Some requirements are still missing. You might need to install them manually." -ForegroundColor Yellow
}

# 2. Setup Python Virtual Environment
if (Get-Command python -ErrorAction SilentlyContinue) {
    Write-Host "Setting up Python virtual environment..." -ForegroundColor Cyan
    if (-not (Test-Path .venv)) {
        python -m venv .venv
        Write-Host "Virtual environment created." -ForegroundColor Green
    }
    
    # Install base requirements
    .\.venv\Scripts\pip.exe install -r requirements.txt 2>$null

    # Install RAG requirements based on mode
    if ($rag -eq "cloud") {
        Write-Host "Installing RAG Cloud dependencies (Gemini API embeddings)..." -ForegroundColor Cyan
        .\.venv\Scripts\pip.exe install -r ai/config/requirements-rag-cloud.txt
        Write-Host "RAG Cloud mode installed." -ForegroundColor Green
    } elseif ($rag -eq "local") {
        Write-Host "Installing RAG Local dependencies (sentence-transformers)..." -ForegroundColor Yellow
        Write-Host "This will download ~1 GB of PyTorch dependencies." -ForegroundColor Yellow
        .\.venv\Scripts\pip.exe install -r ai/config/requirements-rag-local.txt
        Write-Host "RAG Local mode installed." -ForegroundColor Green
    } else {
        Write-Host "RAG disabled. No AI/ML packages installed." -ForegroundColor Gray
    }

    # Update VS Code settings for Python
    $settingsPath = ".vscode/settings.json"
    if (Test-Path $settingsPath) {
        $settings = Get-Content $settingsPath | ConvertFrom-Json
        $settings | Add-Member -MemberType NoteProperty -Name "python.defaultInterpreterPath" -Value "`${workspaceFolder}/.venv/Scripts/python.exe" -Force
        $settings | Add-Member -MemberType NoteProperty -Name "python.terminal.activateEnvInSelectedTerminal" -Value $true -Force
        $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath
        Write-Host "VS Code Python settings updated." -ForegroundColor Green
    }
}

# Optional: Apply GitHub ruleset if 'gh' is logged in
Write-Host "Checking GitHub CLI status..."
if (Get-Command gh -ErrorAction SilentlyContinue) {
    gh auth status --hostname github.com *> $null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Applying GitHub ruleset..."
        .\ai\scripts\helpers\apply-github-config.ps1
    } else {
        Write-Host "Not logged in to GitHub CLI. Skipping automatic ruleset application." -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "Project bootstrapped." -ForegroundColor Green
Write-Host "  Name: $name"
Write-Host "  IDE:  $ide"
Write-Host "  RAG:  $rag"
Write-Host "  Requirements: $requirementsManifest"
