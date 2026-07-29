# C:\opt\cozy\bin\mount-share.ps1
param(
    [string]$ShareServer,
    [string]$ShareName,
    [string]$ShareUser,
    [string]$SharePass
)

$src_path = "\\$ShareServer\$ShareName"
$dst_path = Join-Path $HOME $ShareName.ToLower()
$User = "$ShareServer\$ShareUser"

# --- Connect share via net use (works in non-interactive sessions) ---
$connected = net use $src_path 2>&1 | Select-String "OK|remembered"
if (-not $connected) {
    net use $src_path /user:$User $SharePass /persistent:yes 2>&1 | Out-Null
}

# --- Symlink ---
if (-not (Test-Path $dst_path)) {
    New-Item -ItemType SymbolicLink -Path $dst_path -Target $src_path | Out-Null
}
