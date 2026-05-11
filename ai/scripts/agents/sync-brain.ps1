# Sync AgentBrain Skills and Update Local RAG
# Usage: .\ai\scripts\agents\sync-brain.ps1

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
    
    Write-Host "Updating local RAG vector store..." -ForegroundColor Cyan
    if (Test-Path ".venv\Scripts\python.exe") {
        & ".venv\Scripts\python.exe" "ai/ingestion/doc_parser.py"
    } else {
        python "ai/ingestion/doc_parser.py"
    }
    
    Write-Host "--- Sync Complete ---" -ForegroundColor Green
} else {
    Write-Host "Error: Global Brain not found at $brainPath" -ForegroundColor Red
    exit 1
}
