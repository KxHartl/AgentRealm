$rootDir = git rev-parse --show-toplevel
$manifest = Join-Path $rootDir "config/requirements.list"

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

    $found = Get-Command $command -ErrorAction SilentlyContinue

    if ($found) {
        Write-Host ("{0,-10} {1,-14} {2,-10} {3}" -f $scope, $name, "OK", $notes)
    } else {
        Write-Host ("{0,-10} {1,-14} {2,-10} {3} ({4})" -f $scope, $name, "MISSING", $notes, $installHint)
        if ($required -ne "optional" -and $required -ne "recommended") {
            $status = 1
        }
    }
}

exit $status
