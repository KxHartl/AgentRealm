param (
    [string]$name,
    [string]$ide = "vscode"
)

function Show-Usage {
    Write-Host "Usage: .\bootstrap-project.ps1 -name <project-name> [-ide <vscode|antigravity>]"
}

if (-not $name) {
    Show-Usage
    exit 1
}

$requirementsManifest = "config/requirements.list"

# Update config/project.yaml
(Get-Content config/project.yaml) -replace '^name: .*', "name: `"$name`"" | Set-Content config/project.yaml
(Get-Content config/project.yaml) -replace '^default_ide: .*', "default_ide: `"$ide`" # vscode | antigravity" | Set-Content config/project.yaml

# Update STATE.md
(Get-Content STATE.md) -replace '^- Name: .*', "- Name: $name" | Set-Content STATE.md

if (-not (Select-String -Path config/project.yaml -Pattern '^  requirements:')) {
    Add-Content -Path config/project.yaml -Value "`n  requirements: `"$requirementsManifest`""
}

if (-not (Select-String -Path STATE.md -Pattern '## Requirements')) {
    $requirementsBlock = @"

## Requirements

- Manifest: config/requirements.list
- Check command: scripts/helpers/check-requirements.ps1
- Installation status: _Not checked yet._
"@
    Add-Content -Path STATE.md -Value $requirementsBlock
}

if (-not (Test-Path .agents)) {
    New-Item -ItemType Directory -Path .agents
}

# 1. Check and install requirements
Write-Host "Verifying project requirements..." -ForegroundColor Cyan
.\scripts\helpers\check-requirements.ps1 -Install
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
        .\scripts\helpers\apply-github-config.ps1
    } else {
        Write-Host "Not logged in to GitHub CLI. Skipping automatic ruleset application." -ForegroundColor Gray
    }
}

Write-Host "Project bootstrapped."
Write-Host "Name: $name"
Write-Host "IDE: $ide"
Write-Host "Requirements manifest: $requirementsManifest"
