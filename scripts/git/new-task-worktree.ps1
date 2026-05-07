param (
    [Parameter(Mandatory=$true)]
    [string]$slug
)

$rootDir = git rev-parse --show-toplevel
$branch = "task/$slug"
$worktree = Join-Path $rootDir ".agents/$slug"

Write-Host "Fetching latest changes..."
git -C "$rootDir" fetch --all --prune

$branchExists = git -C "$rootDir" show-ref --verify --quiet "refs/heads/$branch"
if ($LASTEXITCODE -eq 0) {
    Write-Host "Adding worktree for existing branch $branch..."
    git -C "$rootDir" worktree add "$worktree" "$branch"
} else {
    Write-Host "Creating new branch $branch and adding worktree..."
    git -C "$rootDir" worktree add -b "$branch" "$worktree" main
}

Write-Host "Worktree created: $worktree"
Write-Host "Branch: $branch"

# Check terminal settings
$skipTerminalLine = $config | Select-String "skip_external_terminal:"
$skipTerminal = $false
if ($skipTerminalLine -match "(true|false)") {
    $skipTerminal = [System.Convert]::ToBoolean($matches[1])
}

if (-not $skipTerminal) {
    Write-Host "Opening external terminal..."
    if (Get-Command wt.exe -ErrorAction SilentlyContinue) {
        # Use Windows Terminal (respects default profile)
        Start-Process wt.exe -ArgumentList "-d `"$worktree`""
    } else {
        # Fallback to powershell (respects profile if not using -NoProfile)
        Start-Process powershell.exe -ArgumentList "-NoExit", "-Command", "Set-Location '$worktree'"
    }
}

# Launch IDE
$config = Get-Content (Join-Path $rootDir "config/project.yaml")
$ideLine = $config | Select-String "default_ide:"
$ide = "vscode"
if ($ideLine) {
    if ($ideLine -match '"([^"]+)"') {
        $ide = $matches[1]
    }
}

if ($ide -eq "vscode") {
    Write-Host "Launching VS Code..."
    code "$worktree"
} elseif ($ide -eq "antigravity") {
    Write-Host "Launching Antigravity..."
    if (Get-Command antigravity -ErrorAction SilentlyContinue) {
        antigravity "$worktree"
    } else {
        Write-Host "antigravity command not found. Using external terminal."
    }
}
