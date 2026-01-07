function Restart-Claude {
    logging "🔄 Stopping Claude Desktop..." "info"
    Get-Process "Claude" -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep 2
    logging "🚀 Starting Claude Desktop..." "info"
    Start-Process "$env:LOCALAPPDATA\Programs\Claude\Claude.exe"
}

function Edit-ClaudeConfig {
    $configPath = Join-Path $env:APPDATA "Claude\config.json"
    if (Test-Path $configPath) {
        if ($env:EDITOR) {
            & $env:EDITOR $configPath
        } elseif (Get-Command code -ErrorAction SilentlyContinue) {
            & code $configPath
        } else {
            & notepad $configPath
        }
    } else {
        Write-Host "Claude config file not found at $configPath" -ForegroundColor Red
    }
}

function Playnite-Extention-Logs {
    $logPath = Join-Path $env:APPDATA "Playnite\extensions.log"
    if (Test-Path $logPath) {
        Get-Content -Path $logPath -Tail 15 -Wait
    } else {
        Write-Host "Playnite extensions log not found at:"
        Write-Host "    $logPath"
    }
   
}

function Playnite-Logs {
    $logPath = Join-Path $env:APPDATA "Playnite\playnite.log"
    if (Test-Path $logPath) {
        Get-Content -Path $logPath -Tail 15 -Wait
    } else {
        Write-Host "Playnite log not found at:"
        Write-Host "    $logPath"
    }
   
}

function Edit-PowerShellProfile {
    if ($env:EDITOR) {
        & $env:EDITOR $PROFILE.CurrentUserAllHosts
    } elseif (Get-Command code -ErrorAction SilentlyContinue) {
        & code $PROFILE.CurrentUserAllHosts
    } else {
        & notepad $PROFILE.CurrentUserAllHosts
    }
}

function winutil {
    Start-Process pwsh -Verb RunAs -ArgumentList '-NoProfile -Command "iwr -useb https://christitus.com/win | iex"'
}

function ChkVars {
    $varNames = @(
        "PWSH_DEBUG",
        "PWSH_TIMESTAMPS",
        "PWSH_GLYPH",
        "ENABLE_MODULES",
        "ENABLE_CHOCOLATEY",
        "ENABLE_INSHELLISENSE",
        "ENABLE_STARSHIP"
    )
    foreach ($name in $varNames) {
        $val = ${env:$name}
        Write-Host "${name} = ${val}"
    }
}

function Check-Vars {
    $varNames = @(
        "PWSH_LOG_LEVEL",
        "PWSH_TIMESTAMPS", 
        "PWSH_GLYPH",
        "ENABLE_MODULES",
        "ENABLE_CHOCOLATEY",
        "ENABLE_INSHELLISENSE",
        "ENABLE_STARSHIP"
    )
    foreach ($name in $varNames) {
        $val = [System.Environment]::GetEnvironmentVariable($name)
        Write-Host "$name = $val"
    }
}

function Get-VSCodeLatestExthostLog {
    $base = "$env:APPDATA\Code - Insiders\logs"
    
    $latestSession = Get-ChildItem $base -Directory |
                     Sort-Object LastWriteTime -Descending |
                     Select-Object -First 1
    
    if (-not $latestSession) {
        Write-Warning "No VS Code log session found"
        return
    }
    
    $latestWindow = Get-ChildItem $latestSession.FullName -Directory -Filter "window*" |
                    Sort-Object LastWriteTime -Descending |
                    Select-Object -First 1
    
    if (-not $latestWindow) {
        Write-Warning "No window folder found in $($latestSession.Name)"
        return
    }
    
    $logFile = Join-Path $latestWindow.FullName "exthost\exthost.log"
    
    if (Test-Path $logFile) {
        Write-Host "Tailing latest exthost log:" -ForegroundColor Green
        Write-Host $logFile -ForegroundColor Blue
        Get-Content $logFile -Tail 100 -Wait
    } else {
        Write-Warning "exthost.log not found in $($latestWindow.Name)"
    }
}