param (
    [Parameter(Mandatory=$true)]
    [string]$worktreePath
)

if (-not (Test-Path $worktreePath)) {
    Write-Host "Worktree path not found: $worktreePath"
    exit 1
}

Set-Location $worktreePath

if (Get-Command copilot -ErrorAction SilentlyContinue) {
    copilot
} else {
    Write-Host "copilot CLI not found. Install it, then rerun."
    exit 2
}
