param (
    [Parameter(Mandatory=$true)]
    [string]$worktreePath
)

if (-not (Test-Path $worktreePath)) {
    Write-Host "Worktree path not found: $worktreePath"
    exit 1
}

Set-Location $worktreePath

if (Get-Command claude -ErrorAction SilentlyContinue) {
    claude
} else {
    Write-Host "claude CLI not found. Install it, then rerun."
    exit 2
}
