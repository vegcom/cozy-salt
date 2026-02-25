param(
    [string]$ShareServer,
    [string]$ShareName,
    [string]$ShareUser,
    [string]$SharePass
)

$src_path = "\\$ShareServer\$ShareName"
$dst_path = Join-Path $HOME $ShareName.ToLower()

# --- Credentials ---
$User = "$ShareServer\$ShareUser"
$Password = $SharePass | ConvertTo-SecureString -AsPlainText -Force
$Cred = New-Object System.Management.Automation.PSCredential($User, $Password)

$existing = cmdkey /list | Select-String $ShareServer
if (-not $existing) {
    cmdkey /add:$ShareServer /user:$User /pass:($Cred.GetNetworkCredential().Password)
}

# --- Offline Files ---
$offlineFiles = Get-WmiObject -Namespace "root\cimv2" -Class Win32_OfflineFilesCache
if (-not $offlineFiles.Enabled) {
    $offlineFiles.Enable()
}

# --- Pinning ---
$cache = New-Object -ComObject OfflineFiles.Cache
$item = $cache.GetItem($src_path)
if (-not $item.IsPinned) {
    $cache.Pin($src_path, $true)
}

# --- Symlink ---
if (-not (Test-Path $dst_path)) {
    New-Item -ItemType SymbolicLink -Path $dst_path -Target $src_path | Out-Null
}
