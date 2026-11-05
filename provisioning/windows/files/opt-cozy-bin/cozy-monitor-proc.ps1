param (
    [string]$Name = $null, 
    [int]$Id = 0
)

$LogRoot = "$PSScriptRoot/out"

if ($Id -gt 0) {
    $ResolvedName = (Get-Process -Id $CurrentPID -ErrorAction SilentlyContinue).ProcessName
    if (-not $ResolvedName) {
        $TargetName = "Process_$CurrentPID"
    } else {
        $TargetName = $ResolvedName
    }at
} elseif ($Name) {
    $CleanName  = $Name -replace '\.exe$', ''
    $CurrentPID = (Get-Process -Name $CleanName -ErrorAction SilentlyContinue).Id
    $TargetName = $CleanName
}



if (-not $CurrentPID) {
    Write-Error "Could not find a running process matching Name: '$Name' or PID: '$Id'."
    return
}

if (-not $CurrentPID) {
    Write-Error "Could not find a running process matching the provided Name ('$TrackName') or PID ('$TrackPID')."
    return
}

$MessageFilePath = "$LogRoot/${TargetName}_message_history.jsonl"
$MetricsFilePath = "$LogRoot/${TargetName}_metrics_history.jsonl"
$TracesFilePath  = "$LogRoot/${TargetName}_traces_history.jsonl"

$LaunchTime = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")

Start-ThreadJob -Name "SteamMonitor" -ScriptBlock {
    param($PIDToTrack, $MetricsPath, $TracesPath, $ExitLogPath)

    $LaunchTime = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")

    do {
        $proc = Get-CimInstance -Query "SELECT * FROM Win32_Process WHERE ProcessId = $PIDToTrack" -ErrorAction SilentlyContinue

        if ($proc) {
            $metrics = [PSCustomObject]@{
                Timestamp      = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
                MonitorLaunch  = $LaunchTime
                PID            = $proc.ProcessId
                HandleCount    = $proc.HandleCount
                ThreadCount    = $proc.ThreadCount
                WorkingSet     = [Math]::Round(($proc.WorkingSetSize / 1MB), 2)
                VirtualSize    = [Math]::Round(($proc.VirtualSize / 1MB), 2)
                KernelModeTime = $proc.KernelModeTime
                UserModeTime   = $proc.UserModeTime
                ReadTransfer   = [Math]::Round(($proc.ReadTransferCount / 1MB), 2)
                WriteTransfer  = [Math]::Round(($proc.WriteTransferCount / 1MB), 2)
            }

            $CombinedEntry = [PSCustomObject]($proc | Select-Object *)
            $CombinedEntry | Add-Member -NotePropertyName "Timestamp" -NotePropertyValue $metrics.Timestamp -Force
            $CombinedEntry | Add-Member -NotePropertyName "MonitorLaunch" -NotePropertyValue $LaunchTime -Force
            $CombinedEntry | Add-Member -NotePropertyName "Live_MemoryMB" -NotePropertyValue $metrics.WorkingSet -Force

            ($metrics | ConvertTo-Json -Compress) | Out-File -FilePath $MetricsPath -Append -Force
            ($CombinedEntry | ConvertTo-Json -Compress -Depth 100) | Out-File -FilePath $TracesPath -Append -Force

            Start-Sleep -Seconds 5
            $isRunning = $true
        }
        else {
            $isRunning = $false
        }
    } while ($isRunning)

    $exitLog = @{ 
        Timestamp     = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        MonitorLaunch = $LaunchTime
        PID           = $PIDToTrack
        Status        = "Exited" 
    } | ConvertTo-Json -Compress
    $exitLog | Out-File -FilePath $ExitLogPath -Append -Force
} -ArgumentList $CurrentPID, $MetricsFilePath, $TracesFilePath, $MessageFilePath | Out-Null

Write-Host "Telemetry engine active! Background traces initialized at $LaunchTime <3" -ForegroundColor Cyan
