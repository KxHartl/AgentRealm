param (
    [string]$name,
    [string]$ide = "vscode",
    [ValidateSet("none", "cloud", "local")]
    [string]$rag = "none",
    [ValidateSet("none", "global", "local")]
    [string]$brain = "global",
    [string]$brainRepo = "https://github.com/KxHartl/AgentBrain.git"
)

function Show-Usage {
    Write-Host "Usage: .\.ai\scripts\helpers\bootstrap-project.ps1 -name <project-name> [-ide <vscode|antigravity>] [-rag <none|cloud|local>] [-brain <none|global|local>] [-brainRepo <url>]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -name      Project name (required)."
    Write-Host "  -ide       IDE to use (vscode|antigravity). Default: vscode."
    Write-Host "  -rag       RAG mode (none|cloud|local). Default: none."
    Write-Host "  -brain     Brain mode (none|global|local). Default: global."
    Write-Host "  -brainRepo Source URL for AgentBrain clone."
}

if (-not $name) {
    Show-Usage
    exit 1
}

$requirementsManifest = ".ai/config/requirements.list"

# 1. Update project.yaml & STATE.md
Write-Host "Updating project metadata..." -ForegroundColor Cyan
(Get-Content .ai/config/project.yaml) -replace '^name: .*', "name: `"$name`"" | Set-Content .ai/config/project.yaml
(Get-Content .ai/config/project.yaml) -replace '^default_ide: .*', "default_ide: `"$ide`" # vscode | antigravity" | Set-Content .ai/config/project.yaml
(Get-Content .ai/config/project.yaml) -replace '^rag_mode: .*', "rag_mode: `"$rag`" # none | cloud | local" | Set-Content .ai/config/project.yaml
(Get-Content .ai/config/project.yaml) -replace '^brain_mode: .*', "brain_mode: `"$brain`" # none | global | local" | Set-Content .ai/config/project.yaml

$date = Get-Date -Format "yyyy-MM-dd"
$cleanState = @"
# STATE.md

## Project info

- Name: $name
- Type: project
- Owner: $(whoami)

## Requirements

- Manifest: .ai/config/requirements.list
- Check command: .ai/scripts/helpers/check-requirements.ps1
- Installation status: _Not checked yet._

## Current focus
- project-init

- **AgentRealm V3.0**: Integrated Global AgentBrain ($brain mode).

## Backlog

- [ ] Add project source files to src/
- [ ] Add research documents to data/rag/sources/
- [ ] Sync Global Brain skills: .\.ai\scripts\agents\sync-brain.ps1

## Changelog

- $date: **Project Initialized** — V3.0 Architecture with $brain AgentBrain.
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
if (Test-Path .ai/scripts/git/setup-guardrails.ps1) {
    Write-Host "Installing Git Guardrails..." -ForegroundColor Cyan
    .\.ai/scripts/git/setup-guardrails.ps1
}

# 3. Resolve and Verify Brain
$brainPath = ""
if ($brain -eq "global") {
    $homeDir = [System.Environment]::GetFolderPath("UserProfile")
    # V3.0 Standard: .agentrealm for global brain
    $brainPath = Join-Path $homeDir ".agentrealm"
    
    if (-not (Test-Path $brainPath)) {
        Write-Host "Global AgentBrain not found at $brainPath. Attempting to clone from $brainRepo..." -ForegroundColor Cyan
        git clone $brainRepo $brainPath
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Warning: Failed to clone AgentBrain. Creating empty directory." -ForegroundColor Yellow
            New-Item -ItemType Directory -Path $brainPath -Force | Out-Null
        }
    }
} elseif ($brain -eq "local") {
    $brainPath = Join-Path (Get-Location) ".ai/brain"
    if (-not (Test-Path $brainPath)) {
        New-Item -ItemType Directory -Path $brainPath -Force | Out-Null
    }
}

if ($brain -ne "none") {
    Write-Host "Connecting to AgentBrain ($brain) at $brainPath..." -ForegroundColor Cyan
    
    # Update .env
    $envPath = ".env"
    if (Test-Path $envPath) {
        $content = Get-Content $envPath
        if ($content -match "GLOBAL_BRAIN_PATH=") {
            $content = $content -replace "GLOBAL_BRAIN_PATH=.*", "GLOBAL_BRAIN_PATH=$brainPath"
        } else {
            $content += "GLOBAL_BRAIN_PATH=$brainPath"
        }
        $content | Set-Content $envPath
    }

    if (Test-Path "$brainPath\.git") {
        Write-Host "Brain is a git repo. Pulling latest skills..." -ForegroundColor Cyan
        pushd $brainPath
        git pull origin main
        popd
    }
    
    if (Test-Path .ai/scripts/agents/sync-brain.ps1) {
        Write-Host "Syncing Brain to local cache..." -ForegroundColor Cyan
        .\.ai/scripts/agents/sync-brain.ps1
    }
    Write-Host "AgentBrain connected and cached." -ForegroundColor Green
} else {
    Write-Host "AgentBrain disabled (mode: none)." -ForegroundColor Yellow
}

# Update README.md
if (Test-Path README.md) {
    Write-Host "Creating clean project README.md..." -ForegroundColor Cyan
    $cleanReadme = @"
# $name

## Overview
Project **$name**, initialized via AgentRealm template.

## Directory Structure
- \`src/\`: Source code and project scripts.
- \`docs/\`: Documentation and LaTeX files.
- \`data/\`: Datasets and RAG sources.
- \`.ai/\`: AgentRealm engine (infrastructure).

## Getting Started
Check \`STATE.md\` for current progress, tasks, and project goals.
"@
    $cleanReadme | Set-Content README.md
}

# Clear IDEAS.md
if (Test-Path IDEAS.md) {
    Write-Host "Resetting IDEAS.md..." -ForegroundColor Cyan
    $cleanIdeas = @"
# $name - Roadmap & Ideas (Untracked)

This file is not tracked by Git. Use it for personal ideas, brainstorms, and plans for $name.
"@
    $cleanIdeas | Set-Content IDEAS.md
}

if (-not (Test-Path .ai/worktrees)) {
    New-Item -ItemType Directory -Path .ai/worktrees -Force | Out-Null
}

# 4. Check and install requirements
Write-Host "Verifying project requirements..." -ForegroundColor Cyan
.\.ai\scripts\helpers\check-requirements.ps1 -Install

# 5. Setup Python Virtual Environment
function Get-RealPython {
    $py = "python"
    $found = Get-Command $py -ErrorAction SilentlyContinue
    if ($found) {
        & $py --version 2>$null
        if ($LASTEXITCODE -eq 0) { return $py }
    }
    $py = "python3"
    $found = Get-Command $py -ErrorAction SilentlyContinue
    if ($found) {
        & $py --version 2>$null
        if ($LASTEXITCODE -eq 0) { return $py }
    }
    return $null
}

$pyCmd = Get-RealPython
if ($pyCmd) {
    Write-Host "Setting up Python virtual environment using $pyCmd..." -ForegroundColor Cyan
    if (-not (Test-Path .venv)) {
        & $pyCmd -m venv .venv
        Write-Host "Virtual environment created." -ForegroundColor Green
    }

    $pipCmd = ".venv\Scripts\pip.exe"
    if (-not (Test-Path $pipCmd)) { $pipCmd = ".venv\bin\pip" }

    # Install base requirements
    & $pipCmd install -r requirements.txt 2>$null

    # Install RAG requirements based on mode
    if ($rag -eq "cloud") {
        Write-Host "Installing RAG Cloud dependencies..." -ForegroundColor Cyan
        & $pipCmd install -r .ai/config/requirements-rag-cloud.txt
    }
    elseif ($rag -eq "local") {
        Write-Host "Installing RAG Local dependencies..." -ForegroundColor Yellow
        & $pipCmd install -r .ai/config/requirements-rag-local.txt

        # Local LLM Orchestration: Detect and optionally install Ollama
        Write-Host "Checking for Local LLM Orchestrator (Ollama)..." -ForegroundColor Cyan
        $ollama = Get-Command ollama -ErrorAction SilentlyContinue
        if (-not $ollama) {
            Write-Host "Ollama not found. It is recommended for local RAG." -ForegroundColor Yellow
            Write-Host "You can download it from https://ollama.com/" -ForegroundColor White
            # Optional: Automated install could go here if requested
        } else {
            Write-Host "Ollama detected: $($ollama.Source)" -ForegroundColor Green
            # Check if ollama is running
            $ollamaProcess = Get-Process ollama -ErrorAction SilentlyContinue
            if (-not $ollamaProcess) {
                Write-Host "Ollama is installed but not running. Please start Ollama to use local LLMs." -ForegroundColor Yellow
            }
        }
    }

    # Add Tracing placeholders to .env
    $envPath = ".env"
    if (Test-Path $envPath) {
        $envContent = Get-Content $envPath
        if ($envContent -notmatch "LANGSMITH_TRACING=") {
            $tracingLines = @(
                "",
                "# Tracing (LangSmith / Langfuse)",
                "LANGSMITH_TRACING=false",
                "LANGSMITH_ENDPOINT=https://api.smith.langchain.com",
                "LANGSMITH_API_KEY=YOUR_LANGSMITH_API_KEY",
                "LANGSMITH_PROJECT=agentrealm-$name"
            )
            $envContent + $tracingLines | Set-Content $envPath
            Write-Host "Added LangSmith tracing scaffolding to .env." -ForegroundColor Green
        }
    }

    # Update VS Code settings for Python
    $settingsPath = ".vscode/settings.json"
    if (Test-Path $settingsPath) {
        $settings = Get-Content $settingsPath | ConvertFrom-Json
        $interpreterPath = "`${workspaceFolder}/.venv/Scripts/python.exe"
        if (-not (Test-Path ".venv/Scripts/python.exe")) { $interpreterPath = "`${workspaceFolder}/.venv/bin/python" }
        
        $settings | Add-Member -MemberType NoteProperty -Name "python.defaultInterpreterPath" -Value $interpreterPath -Force
        $settings | Add-Member -MemberType NoteProperty -Name "python.terminal.activateEnvInSelectedTerminal" -Value $true -Force
        $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath
        Write-Host "VS Code Python settings updated." -ForegroundColor Green
    }
} else {
    Write-Host "Warning: Valid Python not found. Skipping virtual environment setup." -ForegroundColor Yellow
}

# 6. Sever connection to template (Reset Git)
if (Test-Path .git) {
    Write-Host "Resetting git repository to sever connection with template..." -ForegroundColor Cyan
    Remove-Item .git -Recurse -Force
    git init
    git add .
    git commit -m "Initial commit for $name" | Out-Null
    Write-Host "Git repository reset." -ForegroundColor Green
}

Write-Host ""
Write-Host "Project bootstrapped (V3.0)." -ForegroundColor Green
Write-Host "  Name:  $name"
Write-Host "  Brain: $brain ($brainPath)"
Write-Host "  RAG:   $rag"
Write-Host "  Env:   .env created"
