param (
    [switch]$Install
)

$rootDir = git rev-parse --show-toplevel 2>$null
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($rootDir)) {
    $rootDir = Get-Location
}

$manifest = Join-Path $rootDir ".ai/config/requirements.list"
if (-not (Test-Path $manifest)) {
    if (Test-Path "../../.ai/config/requirements.list") {
        $rootDir = Resolve-Path "../../"
        $manifest = Join-Path $rootDir ".ai/config/requirements.list"
    }
}

if (-not (Test-Path $manifest)) {
    Write-Host "Requirement manifest not found: $manifest"
    exit 2
}

$status = 0
Write-Host ("{0,-10} {1,-14} {2,-10} {3}" -f "SCOPE", "NAME", "STATUS", "DETAILS")

Get-Content $manifest | ForEach-Object {
    $line = $_.Trim()
    if ($line -eq "" -or $line.StartsWith("#")) {
        return
    }

    $parts = $line.Split('|')
    if ($parts.Count -lt 7) { return }

    $scope = $parts[0].Trim()
    $name = $parts[1].Trim()
    $command = $parts[2].Trim()
    $required = $parts[3].Trim()
    $minVersion = $parts[4].Trim()
    $installHint = $parts[5].Trim()
    $notes = $parts[6].Trim()

    $isPythonScope = ($scope -eq "python")
    $found = $false

    if ($isPythonScope) {
        $pyCmd = "python"
        if (Test-Path ".venv/Scripts/python.exe") {
            $pyCmd = ".venv/Scripts/python.exe"
        } elseif (Test-Path ".venv/bin/python") {
            $pyCmd = ".venv/bin/python"
        }
        
        & $pyCmd -c "import $command" 2>$null
        $found = ($LASTEXITCODE -eq 0)
    } else {
        $cmdInfo = Get-Command $command -ErrorAction SilentlyContinue
        if ($cmdInfo) {
            # Check for Windows stub if it's python
            if ($command -eq "python" -or $command -eq "python3") {
                & $command --version 2>$null
                $found = ($LASTEXITCODE -eq 0)
            } else {
                $found = $true
            }
        }
    }

    if ($found) {
        Write-Host ("{0,-10} {1,-14} {2,-10} {3}" -f $scope, $name, "OK", $notes)
    } else {
        if ($Install) {
            Write-Host ("{0,-10} {1,-14} {2,-10} {3}" -f $scope, $name, "INSTALLING", "Attempting install...")
            if ($isPythonScope) {
                $pipCmd = "pip"
                if (Test-Path ".venv/Scripts/pip.exe") {
                    $pipCmd = ".venv/Scripts/pip.exe"
                }
                & $pipCmd install $name
            } else {
                # Try to guess ID from hint or use name
                $wingetId = $name
                if ($installHint -match "Install (.*)") {
                    $wingetId = $matches[1]
                }
                winget install --id $wingetId --silent --accept-package-agreements --accept-source-agreements
            }
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Successfully installed $name" -ForegroundColor Green
            } else {
                Write-Host "Failed to install $name. Please do it manually: $installHint" -ForegroundColor Red
                $status = 1
            }
        } else {
            Write-Host ("{0,-10} {1,-14} {2,-10} {3} ({4})" -f $scope, $name, "MISSING", $notes, $installHint)
            if ($required -ne "optional" -and $required -ne "recommended") {
                $status = 1
            }
        }
    }
}

exit $status
