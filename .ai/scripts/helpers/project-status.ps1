# Project Dashboard
# usage: .\.ai\scripts\helpers\project-status.ps1

$rootDir = git rev-parse --show-toplevel 2>$null
if ($LASTEXITCODE -ne 0) { $rootDir = Get-Location }
Set-Location $rootDir

Write-Host "AgentRealm Project Dashboard" -ForegroundColor Blue -BackgroundColor White
Write-Host "===============================" -ForegroundColor Gray

# 1. Project Info
$projectName = "Unknown"
if (Test-Path ".ai/config/project.yaml") {
    $lines = Get-Content ".ai/config/project.yaml"
    foreach ($line in $lines) {
        if ($line -match 'name:\s*"?([^"\r\n]+)"?\s*$') {
            $projectName = $matches[1]
            break
        }
    }
}
Write-Host "Project: $projectName" -ForegroundColor Cyan
Write-Host "Root: $rootDir" -ForegroundColor Gray
Write-Host ""
 
# 2. Current Focus (from STATE.md)
$state = Get-Content "STATE.md" -Raw
if ($state -match "## Current focus\s*\n\n- (.*)") {
    $focus = $matches[1]
    Write-Host "Current Focus:" -ForegroundColor Yellow
    Write-Host "   $focus"
}
Write-Host ""
 
# 3. Active Worktrees (Task Sandboxes)
Write-Host "Active Task Sandboxes (.ai/worktrees/):" -ForegroundColor Cyan
$worktrees = git worktree list --porcelain | Select-String "worktree "
$foundWorktree = $false
foreach ($wt in $worktrees) {
    $path = $wt.ToString().Replace("worktree ", "")
    if ($path -match "\.ai[\\/]worktrees") {
        $slug = Split-Path $path -Leaf
        Write-Host "   - [$slug] $path" -ForegroundColor Green
        $foundWorktree = $true
    }
}
if (-not $foundWorktree) { Write-Host "   (None)" -ForegroundColor Gray }
Write-Host ""

# 4. System Health Check
Write-Host "System Health:" -ForegroundColor Cyan
.\.ai\scripts\helpers\check-requirements.ps1 | Select-Object -Skip 1 | ForEach-Object {
    if ($_ -match "MISSING") {
        Write-Host "   $_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Tip: Run '.\.ai\scripts\helpers\check-all.ps1' for a full sanity check." -ForegroundColor Gray
