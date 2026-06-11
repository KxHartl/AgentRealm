# Sync AgentBrain Skills and Update Local RAG
# Usage: .\.ai\scripts\agents\sync-brain.ps1

# 1. Load environment variables
if (Test-Path .env) {
    Get-Content .env | Foreach-Object {
        if ($_ -match "^(?<key>[^=]+)=(?<value>.*)$") {
            [System.Environment]::SetEnvironmentVariable($Matches.key, $Matches.value.Trim("'").Trim('"'))
        }
    }
}

$brainPathRaw = [System.Environment]::GetEnvironmentVariable("GLOBAL_BRAIN_PATH")
if (-not $brainPathRaw) { $brainPathRaw = "~/.agentbrain" }

# Resolve ~
$homeDir = [System.Environment]::GetFolderPath("UserProfile")
$brainPath = $brainPathRaw.Replace("~", $homeDir)

Write-Host "--- Syncing Global AgentBrain ---" -ForegroundColor Cyan
Write-Host "Target: $brainPath"

if (Test-Path $brainPath) {
    if (Test-Path "$brainPath\.git") {
        Write-Host "Fetching latest skills from origin..." -ForegroundColor Cyan
        pushd $brainPath
        git pull origin main
        popd
    } else {
        Write-Host "Brain is not a git repository. Skipping pull." -ForegroundColor Gray
    }
    
    # 2. Copy skills to local cache to avoid permission prompts for 'outside workspace' access
    $localCache = ".ai/brain"
    Write-Host "Caching Global Brain skills locally to $localCache..." -ForegroundColor Cyan
    if (-not (Test-Path $localCache)) { New-Item -ItemType Directory -Path $localCache -Force | Out-Null }
    
    # Copy files while excluding .git
    Copy-Item -Path "$brainPath\*" -Destination $localCache -Recurse -Force -Exclude ".git"
    
    Write-Host "Updating local RAG vector store..." -ForegroundColor Cyan
    $pyCmd = "python"
    if (Test-Path ".venv\Scripts\python.exe") {
        $pyCmd = ".venv\Scripts\python.exe"
    } elseif (Test-Path ".venv\bin\python") {
        $pyCmd = ".venv\bin\python"
    }

    # Verify python is real
    & $pyCmd --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        & $pyCmd ".ai/ingestion/doc_parser.py"
    } else {
        Write-Host "Warning: Valid Python not found. Skipping RAG ingestion." -ForegroundColor Yellow
    }
    
    Write-Host "--- Sync Complete (Local Cache Updated) ---" -ForegroundColor Green
} else {
    Write-Host "Error: Global Brain not found at $brainPath" -ForegroundColor Red
    exit 1
}
