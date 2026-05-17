param (
    [Parameter(Mandatory=$true)]
    [string]$worktreePath
)

$rootDir = git rev-parse --show-toplevel

Write-Host "Fetching from origin..."
git -C "$rootDir" fetch origin

Write-Host "Rebasing $worktreePath with origin/main..."
git -C "$worktreePath" rebase origin/main

Write-Host "Synced $worktreePath with origin/main"
