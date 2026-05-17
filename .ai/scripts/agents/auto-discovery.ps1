param (
    [string]$worktreePath
)

Write-Host "--- 🧠 Brain Auto-Discovery ---" -ForegroundColor Cyan

if (-not $worktreePath) {
    Write-Host "Usage: .\auto-discovery.ps1 <path_to_completed_worktree>"
    exit 1
}

$rootDir = git rev-parse --show-toplevel 2>$null
if ($LASTEXITCODE -ne 0) { $rootDir = Get-Location }

$pythonScript = Join-Path $rootDir ".ai/scripts/agents/auto_discovery.py"
if (Test-Path $pythonScript) {
    $pythonCmd = "python"
    if (Test-Path "$rootDir\.venv\Scripts\python.exe") {
        $pythonCmd = "$rootDir\.venv\Scripts\python.exe"
    }
    
    Write-Host "Scanning $worktreePath for new skills..." -ForegroundColor Cyan
    & $pythonCmd $pythonScript $worktreePath
    
    $syncScript = Join-Path $rootDir ".ai/scripts/agents/sync-brain.ps1"
    if (Test-Path $syncScript) {
        Write-Host "Syncing AgentBrain to update local caches..." -ForegroundColor Cyan
        & $syncScript
    }
} else {
    Write-Host "Auto-discovery helper python script not found." -ForegroundColor Red
}
