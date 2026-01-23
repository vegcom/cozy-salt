<#
    System Maintenance Script
    - Elevation check
    - Transcript logging
    - Windows Event Log logging
    - Timing
    - Error handling
    - Update stack reset
    - DISM cleanup + repair
    - SFC scan
#>

# -------------------------------
# Elevation Check
# -------------------------------
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script must be run as Administrator."
    exit 1
}

# -------------------------------
# Logging Setup
# -------------------------------
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$logDir    = "C:\Logs"
$logPath   = "$logDir\HealthRepair-$timestamp.log"

if (-not (Test-Path $logDir)) {
    New-Item -Path $logDir -ItemType Directory -Force | Out-Null
}

Start-Transcript -Path $logPath -Force

# -------------------------------
# Event Log Setup
# -------------------------------
$logName = "SystemMaintenance"
$source  = "HealthRepair"

if (-not (Get-EventLog -List | Where-Object { $_.Log -eq $logName })) {
    New-EventLog -LogName $logName -Source $source
}

function Log-Event {
    param(
        [string]$Message,
        [int]$EventId = 1000
    )
    Write-EventLog -LogName $logName -Source $source -EntryType Information -EventId $EventId -Message $Message
}

# -------------------------------
# Timing Helper
# -------------------------------
function Measure-Step {
    param(
        [string]$Name,
        [scriptblock]$Action
    )

    Write-Host "==> $Name"
    Log-Event -Message "$Name started."

    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    try {
        & $Action
        $sw.Stop()
        Log-Event -Message "$Name completed in $($sw.Elapsed.ToString())."
    }
    catch {
        $sw.Stop()
        Log-Event -Message "$Name FAILED after $($sw.Elapsed.ToString())." -EventId 9001
        Write-Error "$Name failed: $_"
        throw
    }
}

# -------------------------------
# Maintenance Steps
# -------------------------------

Measure-Step -Name "Reset Windows Update Stack" -Action {
    Stop-Service -Name wuauserv -Force
    Stop-Service -Name bits -Force
    Stop-Service -Name cryptsvc -Force

    Rename-Item -Path "C:\Windows\SoftwareDistribution" -NewName "SoftwareDistribution.old" -Force
    Rename-Item -Path "C:\Windows\System32\catroot2" -NewName "catroot2.old" -Force

    Start-Service -Name wuauserv
    Start-Service -Name bits
    Start-Service -Name cryptsvc
}

Measure-Step -Name "DISM Component Cleanup" -Action {
    Dism /Online /Cleanup-Image /StartComponentCleanup /ResetBase
}

Measure-Step -Name "DISM RestoreHealth" -Action {
    Dism /Online /Cleanup-Image /RestoreHealth
}

Measure-Step -Name "SFC Scan" -Action {
    sfc /scannow
}

# -------------------------------
# Cleanup
# -------------------------------
Stop-Transcript
Write-Host "Maintenance complete. Log saved to $logPath"
Log-Event -Message "Maintenance script completed successfully." -EventId 1999
