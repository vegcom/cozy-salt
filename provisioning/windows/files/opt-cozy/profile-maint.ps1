# Profile maintenance script
# Cleans up orphaned/temp profiles (user.HOSTNAME pattern)
# Run elevated: .\profile-maint.ps1 [-WhatIf] [-Force]

param(
    [switch]$WhatIf,
    [switch]$Force
)

$hostname = $env:COMPUTERNAME
$profileListPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"

Write-Host "Profile Maintenance - $hostname" -ForegroundColor Cyan
Write-Host "=" * 50

# Find orphaned profiles (user.HOSTNAME pattern)
$orphanedProfiles = @()

Get-ChildItem $profileListPath | ForEach-Object {
    $sid = $_.PSChildName
    $profilePath = (Get-ItemProperty $_.PSPath).ProfileImagePath

    # Match pattern: username.HOSTNAME (temp profile indicator)
    if ($profilePath -match '\\([^\\]+)\.[A-Z0-9-]+$') {
        $orphanedProfiles += @{
            SID = $sid
            Path = $profilePath
            RegistryKey = $_.PSPath
        }
    }
}

if ($orphanedProfiles.Count -eq 0) {
    Write-Host "`nNo orphaned profiles found." -ForegroundColor Green
    exit 0
}

Write-Host "`nFound $($orphanedProfiles.Count) orphaned profile(s):" -ForegroundColor Yellow
$orphanedProfiles | ForEach-Object {
    Write-Host "  SID:  $($_.SID)" -ForegroundColor Gray
    Write-Host "  Path: $($_.Path)" -ForegroundColor Gray
    Write-Host ""
}

if ($WhatIf) {
    Write-Host "[WhatIf] Would remove the above profiles" -ForegroundColor Magenta
    exit 0
}

if (-not $Force) {
    $confirm = Read-Host "Remove these orphaned profiles? (y/N)"
    if ($confirm -ne 'y') {
        Write-Host "Aborted." -ForegroundColor Red
        exit 1
    }
}

# Remove orphaned profiles
$orphanedProfiles | ForEach-Object {
    Write-Host "Removing: $($_.Path)" -ForegroundColor Yellow

    # Remove registry entry
    try {
        Remove-Item $_.RegistryKey -Recurse -Force -ErrorAction Stop
        Write-Host "  Registry entry removed" -ForegroundColor Green
    } catch {
        Write-Host "  Failed to remove registry: $_" -ForegroundColor Red
    }

    # Remove folder
    if (Test-Path $_.Path) {
        try {
            Remove-Item $_.Path -Recurse -Force -ErrorAction Stop
            Write-Host "  Profile folder removed" -ForegroundColor Green
        } catch {
            Write-Host "  Failed to remove folder: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "  Folder already gone" -ForegroundColor Gray
    }
}

Write-Host "`nProfile maintenance complete." -ForegroundColor Cyan
