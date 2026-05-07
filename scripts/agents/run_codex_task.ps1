param (
    [Parameter(Mandatory=$true)]
    [string]$worktreePath
)

if (-not (Test-Path $worktreePath)) {
    Write-Host "Worktree path not found: $worktreePath"
    exit 1
}

Set-Location $worktreePath

$env:CODEX_HOME = Join-Path (Get-Location) ".codex"
if (-not (Test-Path $env:CODEX_HOME)) {
    New-Item -ItemType Directory -Path $env:CODEX_HOME
}

if (Get-Command codex -ErrorAction SilentlyContinue) {
    codex
} else {
    Write-Host "codex CLI not found. Install it, then rerun."
    exit 2
}
