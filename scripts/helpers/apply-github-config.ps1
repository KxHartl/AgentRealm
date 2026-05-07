# Apply GitHub Ruleset
# Uses 'gh' CLI to import the ruleset from config/github/ruleset.json

$rootDir = git rev-parse --show-toplevel 2>$null
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($rootDir)) {
    $rootDir = Get-Location
}

# If we are in scripts/helpers, try to find the config relative to it
$rulesetFile = Join-Path $rootDir "config/github/ruleset.json"
if (-not (Test-Path $rulesetFile)) {
    if (Test-Path "../../config/github/ruleset.json") {
        $rootDir = Resolve-Path "../../"
        $rulesetFile = Join-Path $rootDir "config/github/ruleset.json"
    }
}

if (-not (Test-Path $rulesetFile)) {
    Write-Host "Ruleset file not found at $rulesetFile" -ForegroundColor Red
    Write-Host "Current location: $(Get-Location)"
    Write-Host "Try running: git config --global --add safe.directory $(Get-Location)"
    exit 1
}

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "GitHub CLI (gh) not found. Please install it first." -ForegroundColor Red
    exit 1
}

# Get repo info
$repo = gh repo view --json nameWithOwner --jq .nameWithOwner
if (-not $repo) {
    Write-Host "Could not determine GitHub repository name." -ForegroundColor Red
    exit 1
}

Write-Host "Applying ruleset to $repo..." -ForegroundColor Cyan

# Apply via API
# Note: This uses the 'gh api' to create a repository ruleset
$apiResponse = gh api "repos/$repo/rulesets" --method POST --input "$rulesetFile" 2>&1
$exitCode = $LASTEXITCODE

if ($exitCode -eq 0) {
    Write-Host "✅ Successfully applied GitHub ruleset!" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to apply ruleset. Check if you have admin permissions and the JSON format is correct." -ForegroundColor Red
    if ($apiResponse) {
        Write-Host "GitHub API response:" -ForegroundColor Yellow
        Write-Host $apiResponse
    }
}
