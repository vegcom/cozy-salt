$steamPath = "C:\Program Files (x86)\Steam\steam.exe"
$arguments = @(
    "-cef-enable-debugging",
    "-cef-force-gpu",
    "-cef-full-memory-crash-report",
    "-cef-in-process-gpu",
    "-cef-single-process",
    "-cef-use-shell-exec=pwsh",
    "-cef-verbose-js-logging",
    "-cef-verbose-logging",
    "-console",
    "-debug_steamapi",
    "-debugbutton",
    "-dev",
    "-enable-keyring",
    "-fasthtml",
    "-fulldesktopres",
    "-oldtraymenu",
    "-silent",
    "-single_core",
    "-system-composer",
    "-websocket"
)

$steamProc = Get-Process -Name "steam" -ErrorAction SilentlyContinue

if ($steamProc) {
    Write-Host "Steam is running. Attempting graceful shutdown..."

    $steamProc | ForEach-Object { $_.CloseMainWindow() } | Out-Null

    $null = Wait-Process -Name "steam" -Timeout 3 -ErrorAction SilentlyContinue

    if (Get-Process -Name "steam" -ErrorAction SilentlyContinue) {
        Write-Warning "Steam didn't close gracefully. Force killing..."
        Stop-Process -Name "steam" -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
    }
}

if ($mode -match '^(m|s|mini|small)$') {
    $arguments += "steam://open/minigameslist"
}

Write-Host "Launching Steam with custom parameters..."
Start-Process -FilePath $steamPath -ArgumentList $arguments
