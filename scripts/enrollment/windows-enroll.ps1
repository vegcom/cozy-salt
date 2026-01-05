# windows-enroll.ps1
# Dockur Windows unattended enrollment for Salt Minion
# Runs as SYSTEM from FirstLogonCommands in Autounattend.xml
# Pre-shared keys are mounted at /mnt/scripts/pki/minion/

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

Write-Host "=== Salt Minion Enrollment (Dockur Windows) ===" -ForegroundColor Cyan

# Configuration
$MasterHost = "salt-master"
$MinionId = "windows-test"
$KeysSourcePath = "D:\scripts\pki\minion"  # Dockur mounts at D:\ or E:\
$SaltBasePath = "C:\opt\salt"
$SaltVersion = "3007.10"

# Try alternate mount points if D:\ doesn't exist
if (-not (Test-Path "D:\scripts")) {
    if (Test-Path "E:\scripts") {
        Write-Host "Scripts mounted at E:\ instead of D:\" -ForegroundColor Yellow
        $KeysSourcePath = "E:\scripts\pki\minion"
    } elseif (Test-Path "\\10.0.2.4\scripts") {
        Write-Host "Scripts available via network mount" -ForegroundColor Yellow
        $KeysSourcePath = "\\10.0.2.4\scripts\pki\minion"
    }
}

Write-Host "Master: $MasterHost"
Write-Host "Minion ID: $MinionId"
Write-Host "Keys source: $KeysSourcePath"
Write-Host ""

# ============================================================================
# Wait for network connectivity
# ============================================================================
Write-Host "Waiting for network connectivity..." -ForegroundColor Green
$maxWaitTime = 300  # 5 minutes
$elapsed = 0
$isConnected = $false

while ($elapsed -lt $maxWaitTime) {
    try {
        $testConnection = Test-NetConnection -ComputerName "8.8.8.8" -Port 53 -WarningAction SilentlyContinue
        if ($testConnection.TcpTestSucceeded -or (Test-NetConnection -ComputerName "1.1.1.1" -WarningAction SilentlyContinue).TcpTestSucceeded) {
            $isConnected = $true
            Write-Host "Network connectivity established" -ForegroundColor Green
            break
        }
    } catch {
        # Silently continue
    }

    Start-Sleep -Seconds 5
    $elapsed += 5
    if ($elapsed % 30 -eq 0) {
        Write-Host "Still waiting for network... ($elapsed seconds elapsed)"
    }
}

if (-not $isConnected) {
    Write-Host "WARNING: Network connectivity not available after 5 minutes. Continuing anyway..." -ForegroundColor Yellow
}

Start-Sleep -Seconds 2

# ============================================================================
# Wait for mounted keys
# ============================================================================
Write-Host "Waiting for key mount ($KeysSourcePath)..." -ForegroundColor Green
$maxWaitTime = 120  # 2 minutes
$elapsed = 0

while ($elapsed -lt $maxWaitTime) {
    if (Test-Path "$KeysSourcePath\minion.pem") {
        Write-Host "Pre-shared keys found" -ForegroundColor Green
        break
    }

    Start-Sleep -Seconds 2
    $elapsed += 2
    if ($elapsed % 10 -eq 0) {
        Write-Host "Waiting for keys... ($elapsed seconds elapsed)"
    }
}

if (-not (Test-Path "$KeysSourcePath\minion.pem")) {
    Write-Host "WARNING: Pre-shared keys not found at $KeysSourcePath. Continuing with key generation..." -ForegroundColor Yellow
}

# ============================================================================
# Download and install Salt Minion
# ============================================================================
$saltExe = "$SaltBasePath\salt-minion.exe"
if (-not (Test-Path $saltExe)) {
    Write-Host "Installing Salt Minion..." -ForegroundColor Green

    $downloadUrl = "https://packages.broadcom.com/artifactory/saltproject-generic/windows/$SaltVersion/Salt-Minion-$SaltVersion-Py3-AMD64-Setup.exe"
    $installerPath = "$env:TEMP\salt-minion-setup.exe"

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Write-Host "  Downloading from $downloadUrl..."
        Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath -UseBasicParsing
        Write-Host "  Running installer..."
        $installArgs = "/S /master=$MasterHost /minion-name=$MinionId"
        Start-Process -FilePath $installerPath -ArgumentList $installArgs -Wait -NoNewWindow
        Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
        Write-Host "  Installation complete" -ForegroundColor Green
    } catch {
        Write-Error "Failed to install Salt Minion: $_"
        Write-Host "Manual download: https://docs.saltproject.io/salt/install-guide/en/latest/topics/install-by-operating-system/windows.html"
        exit 1
    }
} else {
    Write-Host "Salt Minion already installed at $saltExe" -ForegroundColor Green
}

# ============================================================================
# Configure minion with pre-shared keys
# ============================================================================
Write-Host "Configuring Salt Minion..." -ForegroundColor Green

$minionConfigDir = "$SaltBasePath\conf\minion.d"
$minionPkiDir = "$SaltBasePath\conf\pki\minion"

New-Item -ItemType Directory -Path $minionConfigDir -Force | Out-Null
New-Item -ItemType Directory -Path $minionPkiDir -Force | Out-Null

# Create minion configuration
$minionConfig = @"
# Salt Minion Configuration
# Generated by windows-enroll.ps1 (Dockur Windows)

master: $MasterHost
id: $MinionId

# File client settings
file_client: remote

# Grains (custom facts about this minion)
grains:
  roles:
    - workstation
  environment: development

# Logging
log_level: info

# TCP timeouts
tcp_keep_alive: True
tcp_keep_alive_idle: 180
tcp_keep_alive_cnt: 10
tcp_keep_alive_intvl: 30
"@

Set-Content -Path "$minionConfigDir\99-custom.conf" -Value $minionConfig -Force
Write-Host "  Configuration written to $minionConfigDir\99-custom.conf" -ForegroundColor Green

# Copy pre-shared keys if available
if (Test-Path "$KeysSourcePath\minion.pem") {
    Write-Host "  Copying pre-shared keys..." -ForegroundColor Green
    Copy-Item -Path "$KeysSourcePath\minion.pem" -Destination "$minionPkiDir\minion.pem" -Force
    Copy-Item -Path "$KeysSourcePath\minion.pub" -Destination "$minionPkiDir\minion.pub" -Force
    icacls "$minionPkiDir\minion.pem" /inheritance:r /grant:r "SYSTEM:F" | Out-Null
    Write-Host "  Keys copied and permissions set" -ForegroundColor Green
} else {
    Write-Host "  Pre-shared keys not available; Salt will generate keys on first run" -ForegroundColor Yellow
}

# ============================================================================
# Start Salt Minion service
# ============================================================================
Write-Host "Starting salt-minion service..." -ForegroundColor Green
try {
    Start-Service -Name "salt-minion" -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2

    $service = Get-Service -Name "salt-minion" -ErrorAction SilentlyContinue
    if ($service -and $service.Status -eq "Running") {
        Write-Host "Salt Minion service started successfully" -ForegroundColor Green
    } else {
        Write-Host "WARNING: Salt Minion service not running. Attempting to start with sc..." -ForegroundColor Yellow
        & sc.exe start salt-minion 2>&1 | Out-Null
        Start-Sleep -Seconds 3
    }
} catch {
    Write-Host "Warning: Could not manage service: $_" -ForegroundColor Yellow
}

# ============================================================================
# Wait for master connectivity
# ============================================================================
Write-Host "Waiting for master connectivity..." -ForegroundColor Green
$maxWaitTime = 300  # 5 minutes
$elapsed = 0

while ($elapsed -lt $maxWaitTime) {
    try {
        # Use salt-call test.ping with 10 second timeout
        $output = & C:\opt\salt\salt-call.bat test.ping 2>&1
        if ($output -match "True|true") {
            Write-Host "Master connection established!" -ForegroundColor Green
            break
        }
    } catch {
        # Silently continue
    }

    Start-Sleep -Seconds 5
    $elapsed += 5

    if ($elapsed % 30 -eq 0) {
        Write-Host "  Still waiting... ($elapsed seconds elapsed)"
    }
}

if ($elapsed -ge $maxWaitTime) {
    Write-Host ""
    Write-Host "WARNING: Could not connect to master after 5 minutes" -ForegroundColor Yellow
    Write-Host "On the Salt Master, you may need to accept the minion key:"
    Write-Host "  salt-key -a $MinionId"
    Write-Host ""
    Write-Host "Then manually run highstate:"
    Write-Host "  salt '$MinionId' state.highstate"
    Write-Host ""
    Write-Host "Keeping system alive for manual troubleshooting..."
    exit 0
}

# ============================================================================
# Run highstate
# ============================================================================
Write-Host ""
Write-Host "Running state.highstate..." -ForegroundColor Green
Write-Host "============================================================================"

try {
    $output = & C:\opt\salt\salt-call.bat state.highstate --state-output=mixed 2>&1
    Write-Host $output
    Write-Host ""
    Write-Host "Highstate complete!" -ForegroundColor Green
} catch {
    Write-Host "Highstate encountered errors: $_" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== Enrollment Complete ===" -ForegroundColor Green
Write-Host "Minion $MinionId is ready for management"
Write-Host ""

# Keep system alive for container
Write-Host "System will remain online for Salt management..."
