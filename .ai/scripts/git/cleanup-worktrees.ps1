param (
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$paths
)

if ($paths.Count -eq 0) {
    Write-Host "Usage: .\cleanup-worktrees.ps1 <worktree-path> [worktree-path ...]"
    Write-Host "Example: .\cleanup-worktrees.ps1 .ai\worktrees\task-1 .ai\worktrees\task-2"
    exit 1
}

$rootDir = git rev-parse --show-toplevel

foreach ($path in $paths) {
    if (Test-Path $path) {
        Write-Host "Removing worktree: $path"
        git -C "$rootDir" worktree remove "$path"
    } else {
        Write-Host "Skipped (not found): $path"
    }
}

Write-Host "Pruning worktrees..."
git -C "$rootDir" worktree prune
