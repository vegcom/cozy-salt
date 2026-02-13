# Windows login script - MOTD equivalent
# Runs at user logon via win_logonscript
# pastel goth aesthetic - twilite theme

# System info
$Hostname = $env:COMPUTERNAME
$OS = (Get-CimInstance Win32_OperatingSystem).Caption -replace 'Microsoft ',''
$Arch = $env:PROCESSOR_ARCHITECTURE
$Uptime = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
$UptimeSpan = (Get-Date) - $Uptime
$UptimeStr = "{0}d {1}h {2}m" -f $UptimeSpan.Days, $UptimeSpan.Hours, $UptimeSpan.Minutes
$Mem = Get-CimInstance Win32_OperatingSystem
$MemUsed = [math]::Round(($Mem.TotalVisibleMemorySize - $Mem.FreePhysicalMemory) / 1MB, 1)
$MemTotal = [math]::Round($Mem.TotalVisibleMemorySize / 1MB, 1)
$Disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
$DiskUsed = [math]::Round(($Disk.Size - $Disk.FreeSpace) / 1GB, 1)
$DiskTotal = [math]::Round($Disk.Size / 1GB, 1)
$DiskPct = [math]::Round((($Disk.Size - $Disk.FreeSpace) / $Disk.Size) * 100)

# Twilite palette - true color ANSI
$PURPLE = "`e[38;2;217;96;168m"       # #d960a8 - main accent
$BRIGHT_PURPLE = "`e[38;2;232;120;192m"  # #e878c0 - highlights
$CYAN = "`e[38;2;112;201;221m"        # #70c9dd - info
$HOTPINK = "`e[38;2;255;121;198m"     # #ff79c6 - special
$FG = "`e[38;2;216;216;216m"          # #d8d8d8 - text
$X = "`e[0m"                          # reset

Write-Host @"

$PURPLE        .  *  .       *    .        *       .    *
$BRIGHT_PURPLE    *        .    $HOTPINK~ welcome home ~$BRIGHT_PURPLE    .        *
$PURPLE      .    *    .        *      .       *   .

$FG    .--.      $CYAN$Hostname$FG
$FG   /    \     ${PURPLE}os$FG      $CYAN$OS$FG ($Arch)
$FG   \    /     ${PURPLE}uptime$FG  $CYAN$UptimeStr$FG
$FG    '--'      ${PURPLE}memory$FG  $CYAN${MemUsed}G$FG / ${MemTotal}G
$FG   _|__|_     ${PURPLE}disk C:$FG $CYAN${DiskUsed}G$FG / ${DiskTotal}G ($DiskPct%)
$FG  |      |
$FG  |______|

$BRIGHT_PURPLE   .  *  ${HOTPINK}cozy-salt managed$BRIGHT_PURPLE  *  .$X

$FG         ${PURPLE}*$FG stay cozy ${PURPLE}*$FG be gentle ${PURPLE}*$X

$BRIGHT_PURPLE  "the system is down. the system is down."$X
$FG                              - strong bad, probably$X

"@
