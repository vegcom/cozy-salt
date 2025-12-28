# SetupComplete.ps1 - Post-install Salt Minion enrollment
# This script runs after Windows installation to:
#   1. Install Salt Minion
#   2. Configure it to connect to the Salt Master
#   3. Start the service
#
# Place this file at: C:\Windows\Setup\Scripts\SetupComplete.ps1
# (The unattend.xml FirstLogonCommands will execute it)

param(
    # Salt Master IP/hostname - Set this to your Linux Salt Master
    # This should be the IP/hostname of your dedicated Salt Master server
    [string]$Master = $env:SALT_MASTER ?? "salt.example.com",

    # Salt version to install
    [string]$SaltVersion = "3007",

    # Minion ID (defaults to hostname)
    [string]$MinionId = $env:COMPUTERNAME.ToLower()
)

$ErrorActionPreference = "Stop"
$LogFile = "C:\Windows\Temp\salt-enrollment.log"

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Tee-Object -FilePath $LogFile -Append
}

Write-Log "=== Salt Minion Enrollment Starting ==="
Write-Log "Master: $Master"
Write-Log "Minion ID: $MinionId"
Write-Log "Salt Version: $SaltVersion"

# Wait for network
Write-Log "Waiting for network connectivity..."
$maxWait = 120
$waited = 0
while (-not (Test-Connection -ComputerName 8.8.8.8 -Count 1 -Quiet) -and $waited -lt $maxWait) {
    Start-Sleep -Seconds 5
    $waited += 5
    Write-Log "  Waiting... ($waited seconds)"
}

if ($waited -ge $maxWait) {
    Write-Log "ERROR: Network not available after $maxWait seconds"
    exit 1
}
Write-Log "Network is available"

# Check if Salt is already installed
$saltExe = "C:\salt\salt-minion.exe"
if (Test-Path $saltExe) {
    Write-Log "Salt Minion already installed, reconfiguring..."
} else {
    Write-Log "Downloading Salt Minion installer..."

    # Try multiple download sources
    $downloadUrls = @(
        "https://repo.saltproject.io/salt/py3/windows/minor/$SaltVersion/Salt-Minion-$SaltVersion-Py3-AMD64-Setup.exe",
        "https://repo.saltproject.io/windows/Salt-Minion-$SaltVersion-Py3-AMD64-Setup.exe"
    )

    $installerPath = "$env:TEMP\salt-minion-setup.exe"
    $downloaded = $false

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    foreach ($url in $downloadUrls) {
        try {
            Write-Log "  Trying: $url"
            Invoke-WebRequest -Uri $url -OutFile $installerPath -UseBasicParsing -TimeoutSec 300
            $downloaded = $true
            Write-Log "  Downloaded successfully"
            break
        } catch {
            Write-Log "  Failed: $_"
        }
    }

    # Fallback: Try Chocolatey
    if (-not $downloaded) {
        Write-Log "Falling back to Chocolatey installation..."
        try {
            # Install Chocolatey if not present
            if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
                Write-Log "Installing Chocolatey..."
                Set-ExecutionPolicy Bypass -Scope Process -Force
                [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
                Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
            }

            # Install Salt via Chocolatey
            Write-Log "Installing Salt Minion via Chocolatey..."
            choco install saltminion -y --force --params="'/Master:$Master /MinionName:$MinionId'"
            $downloaded = $true
        } catch {
            Write-Log "Chocolatey installation failed: $_"
        }
    }

    # Run installer if downloaded directly
    if ($downloaded -and (Test-Path $installerPath)) {
        Write-Log "Running Salt Minion installer..."
        $installArgs = "/S /master=$Master /minion-name=$MinionId"
        Start-Process -FilePath $installerPath -ArgumentList $installArgs -Wait -NoNewWindow
        Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
    }
}

# Verify installation
if (-not (Test-Path "C:\salt\salt-minion.exe")) {
    Write-Log "ERROR: Salt Minion installation failed"
    exit 1
}

# Configure minion
Write-Log "Configuring Salt Minion..."
$minionConfig = "C:\salt\conf\minion"
$minionDir = "C:\salt\conf\minion.d"

if (-not (Test-Path $minionDir)) {
    New-Item -ItemType Directory -Path $minionDir -Force | Out-Null
}

# Write master configuration
@"
# Auto-configured by SetupComplete.ps1
master: $Master
"@ | Set-Content -Path "$minionDir\master.conf" -Force

# Write minion ID
@"
# Auto-configured by SetupComplete.ps1
id: $MinionId
"@ | Set-Content -Path "$minionDir\id.conf" -Force

# Write grains
@"
# Auto-configured by SetupComplete.ps1
grains:
  roles:
    - workstation
  deployment: pxe
  enrolled: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
"@ | Set-Content -Path "$minionDir\grains.conf" -Force

# Restart Salt Minion service
Write-Log "Starting Salt Minion service..."
Stop-Service -Name salt-minion -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
Start-Service -Name salt-minion

# Verify service is running
Start-Sleep -Seconds 5
$service = Get-Service -Name salt-minion
if ($service.Status -eq "Running") {
    Write-Log "Salt Minion service is running"
} else {
    Write-Log "WARNING: Salt Minion service status: $($service.Status)"
}

Write-Log "=== Salt Minion Enrollment Complete ==="
Write-Log ""
Write-Log "Next steps on Salt Master:"
Write-Log "  1. Accept the minion key: salt-key -a $MinionId"
Write-Log "  2. Test connectivity: salt '$MinionId' test.ping"
Write-Log "  3. Apply states: salt '$MinionId' state.apply"

# Disable auto-logon after first run
Write-Log "Disabling auto-logon..."
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
Set-ItemProperty -Path $regPath -Name "AutoAdminLogon" -Value "0" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path $regPath -Name "DefaultPassword" -ErrorAction SilentlyContinue

Write-Log "Setup complete. Rebooting in 30 seconds..."
Start-Sleep -Seconds 30
Restart-Computer -Force
