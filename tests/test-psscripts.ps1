# Lint all PowerShell scripts with PSScriptAnalyzer

$ErrorActionPreference = "Stop"

Write-Host "=== PowerShell Script Linting with PSScriptAnalyzer ===" -ForegroundColor Cyan

# Check if PSScriptAnalyzer is installed
if (!(Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
    Write-Host "ERROR: PSScriptAnalyzer is not installed" -ForegroundColor Red
    Write-Host "Install: Install-Module -Name PSScriptAnalyzer -Force" -ForegroundColor Yellow
    exit 1
}

Import-Module PSScriptAnalyzer

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$Scripts = Get-ChildItem -Path $ProjectRoot -Recurse -Filter "*.ps1" -File | Where-Object { $_.FullName -notmatch "\\\.git\\" }

if ($Scripts.Count -eq 0) {
    Write-Host "No PowerShell scripts found"
    exit 0
}

$Failed = 0

foreach ($Script in $Scripts) {
    Write-Host "Checking: $($Script.FullName)" -ForegroundColor Gray

    $Results = Invoke-ScriptAnalyzer -Path $Script.FullName -Severity Warning,Error

    if ($Results) {
        $Failed++
        Write-Host "Issues found in $($Script.Name):" -ForegroundColor Yellow
        $Results | Format-Table -AutoSize
    }
}

Write-Host ""
if ($Failed -gt 0) {
    Write-Host "=== FAILED: $Failed script(s) have issues ===" -ForegroundColor Red
    exit 1
} else {
    Write-Host "=== PASSED: All PowerShell scripts are clean ===" -ForegroundColor Green
}
