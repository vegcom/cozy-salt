
function logging {
    param(
        [Parameter(Position=0)]
        [string]$message,
        [Parameter(Position=1)]
        # TODO: convert to int to support 
        [string]$level = "DEBUG"
    )
    $glyphs = @{
        "DEBUG" = "🐛";
        "INFO"  = "✅";
        "WARN"  = "⚠️";
        "ERROR" = "❌";
    }
    $return = @()
    $glyph = $glyphs[$level]

    if ($env:PWSH_DEBUG_TIMESTAMPS) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $return += "$timestamp"
    }

    if ($env:PWSH_GLYPH) {
        $return += "$glyph"
    }
    
    if ($message) {
        $return += "$message"
    }

    if ($return) {
        # Define log level hierarchy
        $logLevels = @{
            "DEBUG" = 0
            "INFO"  = 1
            "WARN"  = 2
            "ERROR" = 3
        }
        
        # Get current log level threshold (default to INFO if not set)
        $currentLevel = if ($env:PWSH_LOG_LEVEL) {
            $logLevels[[string]$env:PWSH_LOG_LEVEL] ?? 1
        } else { 1 }
        
        # Only print if message level >= current threshold
        if ($logLevels[$level] -gt $currentLevel) {
            Write-Host ($return -join '  ')
        }
    }
}

function Script-Loader {
    param([Parameter(Position=0)][array]$scripts)
    foreach ($script in $scripts) {
        if (Test-Path $script) {
            Mark-Time "$script"
            . $script
            Show-Elapsed "$script" -Clear
            if (${LASTEXITCODE} -ne 0) {
                logging "load failed $script" "WARN"
            } else {
                logging "load passed $script" "DEBUG"
            }
        }
    }
}

function To-Bool($val, $default=$false) {
    if ($null -eq $val) { return $default }
    if ($val -is [bool]) { return $val }
    $str = $val.ToString().ToLower()
    if ($str -eq 'true' -or $str -eq '1') { return $true }
    if ($str -eq 'false' -or $str -eq '0') { return $false }
    return $default
}


