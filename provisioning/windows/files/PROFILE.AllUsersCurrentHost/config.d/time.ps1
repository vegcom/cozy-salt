# Timing utilities for performance monitoring
if (-not $script:timeMarkers) { $script:timeMarkers = @{} }

function Mark-Time {
    <#
    .SYNOPSIS
        Start or mark a timing checkpoint
    .PARAMETER name
        Name of the timing marker (default: "default")
    #>
    param(
        [Parameter(Position=0)]
        [string]$name = "default"
    )
    $script:timeMarkers[$name] = [System.Diagnostics.Stopwatch]::GetTimestamp()
}

function Show-Elapsed {
    <#
    .SYNOPSIS
        Display elapsed time since last Mark-Time call
    .PARAMETER name
        Name of the timing marker to check (default: "default")
    .PARAMETER Clear
        Remove the marker after displaying
    #>
    param(
        [Parameter(Position=0)]
        [string]$name = "default",
        [switch]$Clear
    )

    if ($script:timeMarkers.ContainsKey($name)) {
        $elapsed = [System.Diagnostics.Stopwatch]::GetElapsedTime($script:timeMarkers[$name])
        $truncatedName = if ($name.Length -gt 90) { $name.Substring(0, 87) + "..." } else { $name }
        $nameCol = $truncatedName.PadRight(90).Substring(0, 90)
        $timerCol = "⏲️"
        $msCol = ([math]::Round($elapsed.TotalMilliseconds, 2).ToString() + " ms").PadLeft(12)

        if ($env:PWSH_LOG_LEVEL -and $env:PWSH_LOG_LEVEL -ne "DEBUG") {
            if (Get-Command logging -ErrorAction SilentlyContinue) {
                logging "$nameCol $timerCol $msCol" "INFO"
            } else {
                Write-Host "$nameCol $timerCol $msCol"
            }
        }

        if ($Clear) { $script:timeMarkers.Remove($name) }
    } else {
        if (Get-Command logging -ErrorAction SilentlyContinue) {
            logging "No time marker found with name: $name" "WARN"
        } else {
            Write-Host "No time marker found with name: $name" -ForegroundColor Yellow
        }
    }
}
