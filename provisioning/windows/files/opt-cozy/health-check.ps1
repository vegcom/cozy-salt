<#
    Windows Health Check Script
    - Runs DISM ScanHealth
    - Logs to SystemMaintenance event log
    - Returns exit code for Salt reactor

    Exit codes:
      0 = healthy
      1 = repairable corruption found (triggers emergency-maint.ps1)
#>

# -------------------------------
# Elevation Check
# -------------------------------
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script must be run as Administrator."
    exit 99
}

# -------------------------------
# Event Log Setup
# -------------------------------
$logName = "SystemMaintenance"
$source  = "HealthCheck"

if (-not (Get-EventLog -List | Where-Object { $_.Log -eq $logName })) {
    New-EventLog -LogName $logName -Source $source
}

function Log-Event {
    param(
        [string]$Message,
        [string]$EntryType = "Information",
        [int]$EventId = 1000
    )
    Write-EventLog -LogName $logName -Source $source -EntryType $EntryType -EventId $EventId -Message $Message
}

# -------------------------------
# Run ScanHealth
# -------------------------------
Log-Event -Message "Starting DISM ScanHealth check."

$null = Dism /Online /Cleanup-Image /ScanHealth
$exitCode = $LASTEXITCODE

if ($exitCode -eq 0) {
    Log-Event -Message "ScanHealth completed: System is healthy." -EventId 1000
    Write-Host "System is healthy."
} else {
    Log-Event -Message "ScanHealth completed: Corruption detected (exit code $exitCode). Repair recommended." -EntryType "Warning" -EventId 2000
    Write-Host "Corruption detected. Repair recommended."

    # Fire Salt event to trigger reactor
    $minion = $env:COMPUTERNAME
    & salt-call event.fire_master "{`"minion`": `"$minion`", `"exitcode`": $exitCode}" "cozy/windows/health-check/failed" 2>$null
}

exit $exitCode
