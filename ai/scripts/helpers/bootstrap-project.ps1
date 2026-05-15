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
    Write-Host ""
    Write-Host "Global Brain:"
    Write-Host "  This project automatically connects to ~/.agentbrain as the SSOT."
}

if (-not $name) {
    Show-Usage
    exit 1
}

$requirementsManifest = "ai/config/requirements.list"

# 1. Update project.yaml & STATE.md
Write-Host "Updating project metadata..." -ForegroundColor Cyan
(Get-Content ai/config/project.yaml) -replace '^name: .*', "name: `"$name`"" | Set-Content ai/config/project.yaml
(Get-Content ai/config/project.yaml) -replace '^default_ide: .*', "default_ide: `"$ide`" # vscode | antigravity" | Set-Content ai/config/project.yaml
(Get-Content ai/config/project.yaml) -replace '^rag_mode: .*', "rag_mode: `"$rag`" # none | cloud | local" | Set-Content ai/config/project.yaml

$date = Get-Date -Format "yyyy-MM-dd"
$cleanState = @"
# STATE.md

## Project info

- Name: $name
- Type: seminar
- Owner: $(whoami)

## Requirements

- Manifest: ai/config/requirements.list
- Check command: ai/scripts/helpers/check-requirements.ps1
- Installation status: _Not checked yet._

## Current focus
- project-init

- **AgentRealm V2.4**: Integrated Global AgentBrain (~/.agentbrain).

## Backlog

- [ ] Add project source files to src/
- [ ] Add research documents to data/rag/sources/
- [ ] Sync Global Brain skills: .\ai\scripts\agents\sync-brain.ps1

## Changelog

- $date: **Project Initialized** — V2.4 Architecture with Global AgentBrain.
"@
$cleanState | Set-Content STATE.md

# 2. Setup .env from .env.example
if (-not (Test-Path .env)) {
    Write-Host "Creating .env from .env.example..." -ForegroundColor Cyan
    Copy-Item .env.example .env
}

# .env Verification (Guardrail)
Write-Host "Verifying .env security..." -ForegroundColor Cyan
$envContent = Get-Content .env
$dangerousKeys = @("GOOGLE_API_KEY", "OPENAI_API_KEY", "ANTHROPIC_API_KEY", "QDRANT_API_KEY")
foreach ($key in $dangerousKeys) {
    if ($envContent -match "^$key=(?!YOUR_).*$") {
        Write-Host "WARNING: Real API key detected for $key in .env! Ensure this file is never committed." -ForegroundColor Yellow
    }
}

# Setup Git Guardrails
if (Test-Path ai/scripts/git/setup-guardrails.ps1) {
    Write-Host "Installing Git Guardrails..." -ForegroundColor Cyan
    .\ai/scripts/git/setup-guardrails.ps1
}

# 3. Resolve and Verify Global Brain
$homeDir = [System.Environment]::GetFolderPath("UserProfile")
$brainPath = "$homeDir\.agentbrain"

Write-Host "Connecting to Global AgentBrain at $brainPath..." -ForegroundColor Cyan
if (Test-Path $brainPath) {
    $content = Get-Content .env
    $envBrainPath = $brainPath -replace '\\', '/'
    if ($content -match "GLOBAL_BRAIN_PATH=") {
        $content = $content -replace "GLOBAL_BRAIN_PATH=.*", "GLOBAL_BRAIN_PATH=$envBrainPath"
    } else {
        $content += "GLOBAL_BRAIN_PATH=$envBrainPath"
    }
    $content | Set-Content .env
    if (Test-Path "$brainPath\.git") {
        Write-Host "Brain is a git repo. Pulling latest skills..." -ForegroundColor Cyan
        pushd $brainPath
        git pull origin main
        popd
    }
    # Sync and Cache Global Brain locally
    if (Test-Path ai/scripts/agents/sync-brain.ps1) {
        Write-Host "Syncing Global Brain to local cache..." -ForegroundColor Cyan
        .\ai/scripts/agents/sync-brain.ps1
    }
    Write-Host "Global Brain connected and cached in ai/brain." -ForegroundColor Green
} else {
    Write-Host "Warning: Global Brain not found at $brainPath. RAG will only use local project data." -ForegroundColor Yellow
}

# Update README.md
if (Test-Path README.md) {
    (Get-Content README.md) -replace '^# AgentRealm', "# $name" | Set-Content README.md
    (Get-Content README.md) -replace 'Universal template for \*\*projects, seminars, and research\*\*', "Project for **$name**, built using AgentRealm template" | Set-Content README.md
}

if (-not (Test-Path ai/worktrees)) {
    New-Item -ItemType Directory -Path ai/worktrees -Force | Out-Null
}

# 4. Check and install requirements
Write-Host "Verifying project requirements..." -ForegroundColor Cyan
.\ai\scripts\helpers\check-requirements.ps1 -Install

# 5. Setup Python Virtual Environment
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
        Write-Host "Installing RAG Cloud dependencies..." -ForegroundColor Cyan
        .\.venv\Scripts\pip.exe install -r ai/config/requirements-rag-cloud.txt
    } elseif ($rag -eq "local") {
        Write-Host "Installing RAG Local dependencies..." -ForegroundColor Yellow
        .\.venv\Scripts\pip.exe install -r ai/config/requirements-rag-local.txt
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

Write-Host ""
Write-Host "Project bootstrapped (V2.4)." -ForegroundColor Green
Write-Host "  Name:  $name"
Write-Host "  Brain: $brainPath"
Write-Host "  RAG:   $rag"
Write-Host "  Env:   .env created"
