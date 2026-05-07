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

Write-Host "Project bootstrapped."
Write-Host "Name: $name"
Write-Host "IDE: $ide"
Write-Host "Requirements manifest: $requirementsManifest"
