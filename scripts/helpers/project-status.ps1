# Project Dashboard
# usage: .\project-status.ps1

$rootDir = git rev-parse --show-toplevel 2>$null
if ($LASTEXITCODE -ne 0) { $rootDir = Get-Location }
Set-Location $rootDir

Write-Host "🌌 AgentRealm Project Dashboard" -ForegroundColor Blue -BackgroundColor White
Write-Host "===============================" -ForegroundColor Gray

# 1. Project Info
$projectName = "Unknown"
if (Test-Path "config/project.yaml") {
    $yamlContent = Get-Content "config/project.yaml"
    if ($yamlContent -match "name:\s*`"?(.*?)`"?\s*$") {
        $projectName = $matches[1]
    }
}
Write-Host "Project: $projectName" -ForegroundColor Cyan
Write-Host "Root: $rootDir" -ForegroundColor Gray
Write-Host ""

# 2. Current Focus (from STATE.md)
$state = Get-Content "STATE.md" -Raw
if ($state -match "## Current focus\s*\n\n- (.*)") {
    $focus = $matches[1]
    Write-Host "🎯 Current Focus:" -ForegroundColor Yellow
    Write-Host "   $focus"
}
Write-Host ""

# 3. Active Worktrees (Task Sandboxes)
Write-Host "🛡️ Active Task Sandboxes (.agents/):" -ForegroundColor Cyan
$worktrees = git worktree list --porcelain | Select-String "worktree "
$foundWorktree = $false
foreach ($wt in $worktrees) {
    $path = $wt.ToString().Replace("worktree ", "")
    if ($path -match "\.agents") {
        $slug = Split-Path $path -Leaf
        Write-Host "   - [$slug] $path" -ForegroundColor Green
        $foundWorktree = $true
    }
}
if (-not $foundWorktree) { Write-Host "   (None)" -ForegroundColor Gray }
Write-Host ""

# 4. System Health Check
Write-Host "🔍 System Health:" -ForegroundColor Cyan
.\scripts\helpers\check-requirements.ps1 | Select-Object -Skip 1 | ForEach-Object {
    if ($_ -match "MISSING") {
        Write-Host "   ❌ $_" -ForegroundColor Red
    } elseif ($_ -match "OK") {
        # Silent OK
    }
}

Write-Host ""
Write-Host "Tip: Run '.\scripts\helpers\check-all.ps1' for a full sanity check." -ForegroundColor Gray
