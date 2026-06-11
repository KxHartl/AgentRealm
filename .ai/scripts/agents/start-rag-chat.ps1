# Start RAG Chat - Interactive CRAG terminal interface
# Usage: .\.ai\scripts\agents\start-rag-chat.ps1 [-Ingest]

param (
    [switch]$Ingest
)

$rootDir = git rev-parse --show-toplevel 2>$null
if (-not $rootDir) { $rootDir = Get-Location }

$VenvPath = Join-Path $rootDir ".venv"
if (Test-Path $VenvPath) {
    $PythonExe = Join-Path $VenvPath "Scripts\python.exe"
} else {
    $PythonExe = "python"
}

if ($Ingest) {
    Write-Host "Running ingestion pipeline..." -ForegroundColor Cyan
    & $PythonExe (Join-Path $rootDir ".ai/ingestion/doc_parser.py")
    Write-Host ""
}

Write-Host "=== AgentRealm CRAG Chat ===" -ForegroundColor Blue
Write-Host "Type your question. Type 'quit' to exit." -ForegroundColor Gray
Write-Host ""

while ($true) {
    $question = Read-Host "You"
    if ($question -eq "quit" -or $question -eq "exit") { break }
    if ([string]::IsNullOrWhiteSpace($question)) { continue }
    $cleanRootDir = $rootDir -replace '\\','/'
    & $PythonExe -c "import sys; sys.path.insert(0, '$cleanRootDir'); hasattr(sys.stdout, 'reconfigure') and sys.stdout.reconfigure(encoding='utf-8'); from ai.rag_core.graph import query; print(query(sys.argv[1]))" $question
    Write-Host ""
}
