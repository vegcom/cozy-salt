# entrypoint-minion.ps1: Dockur Windows unattended enrollment for Salt Minion
# Runs as SYSTEM from FirstLogonCommands in Autounattend.xml

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Configuration (use env vars if available, else defaults)
$MasterHost = $env:SALT_MASTER_HOST ?? "salt"
$MinionId = $env:SALT_MINION_ID ?? "windows-test"
$SaltVersion = $env:SALT_VERSION ?? "3007.10"

# Locate keys (Dockur mounts at D:\, E:\, or network)
$KeysSourcePath = "D:\scripts\pki\minion"
if (-not (Test-Path "D:\scripts")) {
    if (Test-Path "E:\scripts") {
        $KeysSourcePath = "E:\scripts\pki\minion"
    } elseif (Test-Path "\\10.0.2.4\scripts") {
        $KeysSourcePath = "\\10.0.2.4\scripts\pki\minion"
    }
}

$SaltBasePath = "C:\opt\salt"

Write-Host "Minion enrollment: master=$MasterHost id=$MinionId"

# Wait for network (max 5 min)
Write-Host "Waiting for network connectivity..."
for ($i = 0; $i -lt 300; $i += 5) {
    try {
        if ((Test-NetConnection "8.8.8.8" -Port 53 -WarningAction SilentlyContinue).TcpTestSucceeded -or
            (Test-NetConnection "1.1.1.1" -WarningAction SilentlyContinue).TcpTestSucceeded) {
            Write-Host "Network ready"
            break
        }
    } catch { }
    if ($i % 30 -eq 0 -and $i -gt 0) { Write-Host "  Still waiting... (${i}s)" }
    Start-Sleep -Seconds 5
}

# Wait for key mount (max 2 min)
Write-Host "Waiting for pre-shared keys..."
for ($i = 0; $i -lt 120; $i += 2) {
    if (Test-Path "$KeysSourcePath\minion.pem") {
        Write-Host "Keys found"
        break
    }
    if ($i % 10 -eq 0 -and $i -gt 0) { Write-Host "  Still waiting... (${i}s)" }
    Start-Sleep -Seconds 2
}

# Install Salt if needed
$saltExe = "$SaltBasePath\salt-minion.exe"
if (-not (Test-Path $saltExe)) {
    Write-Host "Installing Salt Minion $SaltVersion..."
    $url = "https://packages.broadcom.com/artifactory/saltproject-generic/windows/$SaltVersion/Salt-Minion-$SaltVersion-Py3-AMD64-Setup.exe"
    $installer = "$env:TEMP\salt-minion-setup.exe"

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $url -OutFile $installer -UseBasicParsing -ErrorAction Stop
        $args = "/S /master=$MasterHost /minion-name=$MinionId"
        Start-Process -FilePath $installer -ArgumentList $args -Wait -NoNewWindow
        Remove-Item $installer -Force -ErrorAction SilentlyContinue
        Write-Host "Salt Minion installed"
    } catch {
        Write-Error "Failed to install Salt: $_`nSee: https://docs.saltproject.io/salt/install-guide/en/latest/topics/install-by-operating-system/windows.html"
    }
}

# Configure minion
Write-Host "Configuring minion..."
$confDir = "$SaltBasePath\conf\minion.d"
$pkiDir = "$SaltBasePath\conf\pki\minion"
New-Item -ItemType Directory -Path $confDir, $pkiDir -Force | Out-Null

$config = @"
master: $MasterHost
id: $MinionId
file_client: remote
log_level: info
grains:
  roles:
    - workstation
  environment: development
tcp_keep_alive: True
tcp_keep_alive_idle: 180
tcp_keep_alive_cnt: 10
tcp_keep_alive_intvl: 30
"@
Set-Content -Path "$confDir\99-custom.conf" -Value $config -Force

# Copy pre-shared keys if available
if (Test-Path "$KeysSourcePath\minion.pem") {
    Write-Host "Copying pre-shared keys..."
    Copy-Item -Path "$KeysSourcePath\minion.pem" -Destination "$pkiDir\minion.pem" -Force
    Copy-Item -Path "$KeysSourcePath\minion.pub" -Destination "$pkiDir\minion.pub" -Force
    icacls "$pkiDir\minion.pem" /inheritance:r /grant:r "SYSTEM:F" | Out-Null
}

# Start service
Write-Host "Starting salt-minion service..."
Start-Service -Name "salt-minion" -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
if ((Get-Service "salt-minion" -ErrorAction SilentlyContinue).Status -eq "Running") {
    Write-Host "Service started"
} else {
    & sc.exe start salt-minion 2>&1 | Out-Null
    Start-Sleep -Seconds 3
}

# Wait for master connectivity (max 5 min)
Write-Host "Waiting for master connection..."
for ($i = 0; $i -lt 300; $i += 5) {
    try {
        $output = & C:\opt\salt\salt-call.bat test.ping 2>&1
        if ($output -match "True|true") {
            Write-Host "Master connected - running highstate"
            & C:\opt\salt\salt-call.bat state.highstate --state-output=mixed 2>&1
            Write-Host "Enrollment complete"
            exit 0
        }
    } catch { }
    if ($i % 30 -eq 0 -and $i -gt 0) { Write-Host "  Still waiting... (${i}s)" }
    Start-Sleep -Seconds 5
}

Write-Host "WARNING: Could not connect to master after 5 minutes"
Write-Host "To troubleshoot on master: salt-key -a $MinionId && salt '$MinionId' state.highstate"
Write-Host "System ready for manual troubleshooting"
