param (
    [Parameter(Mandatory=$true)]
    [string]$slug
)

$rootDir = git rev-parse --show-toplevel
$branch = "task/$slug"
$worktree = Join-Path $rootDir ".ai/worktrees/$slug"

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

# Ensure the new worktree is marked as safe (prevents "dubious ownership" errors on network shares)
git config --global --add safe.directory "$worktree"

# Update STATE.md focus
$stateFile = Join-Path $rootDir "STATE.md"
if (Test-Path $stateFile) {
    $content = Get-Content $stateFile
    $newContent = @()
    $foundFocus = $false
    foreach ($line in $content) {
        $newContent += $line
        if ($line -match "## Current focus") {
            $newContent += "- $slug"
            $foundFocus = $true
        }
    }
    if ($foundFocus) {
        $newContent | Set-Content $stateFile
        Write-Host "Updated STATE.md focus with: $slug"
    }
}

# Check terminal settings
$config = Get-Content (Join-Path $rootDir ".ai/config/project.yaml")
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
