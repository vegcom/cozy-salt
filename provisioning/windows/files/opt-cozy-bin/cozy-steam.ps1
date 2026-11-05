#!/usr/bin/env pwsh

$steamBin = "/Program Files (x86)/Steam/steam.exe"

try {
    $steamArguments = @(
        "-cef-enable-debugging",
        "-cef-enable-gpu-debugging",
        "-cef-force-gpu",
        "-cef-force-sandbox",
        "-cef-full-memory-crash-report",
        "-cef-in-process-gpu",
        "-cef-single-process='pwsh'"
        "-cef-use-shell-exec",
        "-cef-verbose-js-logging",
        "-cef-verbose-logging",
        "-console",
        "-debug_steamapi",
        "-debugbutton",
        "-disable-winh264",
        "-fasthtml",
        "-forcedeckcontroller"
        "-fs_log",
        "-fs_logbins",
        "-fs_target"
        "-fulldesktopres",
        "-lognetapi",
        "-oldtraymenu",
        "-silent",
        "-single_core",
        "-system-composer"
    )

    if ($mode -match '^(m|s|mini|small)$') {
        $steamArguments += "steam://open/minigameslist"
    }
    Start-Process -LoadUserProfile -NoNewWindow -FilePath $SteamBin -ArgumentList $steamArguments
} catch {
    throw "Failed: $_"
}
