<#
    Test winget --scope machine compatibility
    Pulls package list from salt pillar, tests each package
    Outputs which packages fail with --scope machine flag

    Usage: salt-call cp.get_file salt://scripts/test-winget-scope.ps1 C:\opt\cozy\test-winget-scope.ps1
           pwsh C:\opt\cozy\test-winget-scope.ps1
#>

# Get packages.sls via salt file server
$tempFile = "$env:TEMP\packages.sls"
salt-call cp.get_file salt://packages.sls $tempFile 2>$null | Out-Null

if (-not (Test-Path $tempFile)) {
    Write-Host "ERROR: Could not fetch salt://packages.sls" -ForegroundColor Red
    Write-Host "Make sure salt-minion can reach the master or file_roots is configured" -ForegroundColor Yellow
    exit 1
}

# Parse YAML (powershell-yaml module or manual)
$systemPkgs = @()

# Simple regex extraction for winget.system packages
$content = Get-Content $tempFile -Raw
$inSystem = $false
$inCategory = $false

foreach ($line in (Get-Content $tempFile)) {
    if ($line -match '^\s{4}system:') { $inSystem = $true; continue }
    if ($line -match '^\s{4}userland:') { $inSystem = $false; continue }
    if ($line -match '^\s{4}\w+:' -and $inSystem -eq $false) { continue }

    if ($inSystem) {
        # Match package IDs (lines with brackets or list items)
        if ($line -match '\[([^\]]+)\]') {
            $pkgs = $matches[1] -split ',\s*' | ForEach-Object { $_.Trim() }
            $systemPkgs += $pkgs
        }
        elseif ($line -match '^\s+-\s+(.+)$') {
            $systemPkgs += $matches[1].Trim()
        }
    }
}

Remove-Item $tempFile -Force -ErrorAction SilentlyContinue

Write-Host "Testing $($systemPkgs.Count) packages for --scope machine compatibility`n" -ForegroundColor Cyan

$needsNoScope = @()
$worksWithScope = @()

foreach ($pkg in $systemPkgs) {
    Write-Host "Testing: $pkg ... " -NoNewline

    # Check if already installed (but still test scope compatibility)
    $installed = winget list --exact --id $pkg 2>$null | Select-String -Quiet -Pattern $pkg

    # Test with --scope machine (check if installer exists for this scope)
    $result = winget install --scope machine --exact --id $pkg --accept-source-agreements 2>&1

    if ($result -match "No applicable installer found" -or $result -match "No package found") {
        $status = if ($installed) { "NEEDS NO-SCOPE (installed)" } else { "NEEDS NO-SCOPE" }
        Write-Host $status -ForegroundColor Red
        $needsNoScope += $pkg
    } else {
        $status = if ($installed) { "OK (installed)" } else { "OK" }
        Write-Host $status -ForegroundColor Green
        $worksWithScope += $pkg
    }
}

Write-Host "`n=== SUMMARY ===" -ForegroundColor Cyan
Write-Host "Works with --scope machine: $($worksWithScope.Count)"
Write-Host "Needs no scope flag: $($needsNoScope.Count)"

if ($needsNoScope.Count -gt 0) {
    Write-Host "`nPackages needing no-scope:" -ForegroundColor Yellow
    $needsNoScope | ForEach-Object { Write-Host "  - $_" }
}
