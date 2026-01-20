<#
.SYNOPSIS
    Windows bootstrap wrapper for Salt Minion installation.

.DESCRIPTION
    Downloads Python if needed and runs the cross-platform installer.
    Can be run directly via: irm https://raw.githubusercontent.com/.../install-minion.ps1 | iex

.PARAMETER Master
    Salt master hostname or IP address.

.PARAMETER MinionId
    Minion ID (hostname for this minion).

.PARAMETER Roles
    Comma-separated list of roles.

.EXAMPLE
    .\install-minion.ps1 -Master salt.example.com -MinionId workstation01 -Roles workstation,developer
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Master,

    [Parameter(Mandatory=$true)]
    [string]$MinionId,

    [Parameter(Mandatory=$true)]
    [string]$Roles,

    [switch]$Force
)

$ErrorActionPreference = "Stop"

# Configuration
$PythonVersion = "3.12.4"
$PythonUrl = "https://www.python.org/ftp/python/$PythonVersion/python-$PythonVersion-embed-amd64.zip"
$TempDir = "$env:TEMP\salt-enrollment"
$PythonDir = "$TempDir\python"

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-Python {
    # Check if Python is already available
    $python = Get-Command python -ErrorAction SilentlyContinue
    if ($python) {
        $version = & python --version 2>&1
        if ($version -match "Python 3\.") {
            Write-Host "Found system Python: $version"
            return "python"
        }
    }

    # Check for embedded Python
    if (Test-Path "$PythonDir\python.exe") {
        Write-Host "Using embedded Python"
        return "$PythonDir\python.exe"
    }

    # Download embedded Python
    Write-Host "Downloading Python $PythonVersion..."
    New-Item -ItemType Directory -Path $PythonDir -Force | Out-Null

    $zipPath = "$TempDir\python.zip"
    Invoke-WebRequest -Uri $PythonUrl -OutFile $zipPath -UseBasicParsing

    Write-Host "Extracting Python..."
    Expand-Archive -Path $zipPath -DestinationPath $PythonDir -Force
    Remove-Item $zipPath

    return "$PythonDir\python.exe"
}

function Get-EnrollmentScripts {
    $scriptDir = Split-Path -Parent $MyInvocation.ScriptName

    # If lib directory exists locally, use it
    if (Test-Path "$scriptDir\lib\common.py") {
        return $scriptDir
    }

    # Otherwise, download from repository
    Write-Host "Downloading enrollment scripts..."
    $repoBase = "https://raw.githubusercontent.com/vegcom/cozy-salt/main/scripts/enrollment"

    $files = @(
        "install-minion.py",
        "lib/__init__.py",
        "lib/common.py",
        "lib/arch/__init__.py",
        "lib/debian/__init__.py",
        "lib/rhel/__init__.py",
        "lib/windows/__init__.py"
    )

    foreach ($file in $files) {
        $localPath = "$TempDir\$file"
        $dir = Split-Path -Parent $localPath
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        Invoke-WebRequest -Uri "$repoBase/$file" -OutFile $localPath -UseBasicParsing
    }

    return $TempDir
}

# Main
Write-Host "=== Salt Minion Installer (Windows Bootstrap) ==="
Write-Host ""

if (-not (Test-Administrator)) {
    Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again."
    exit 1
}

# Create temp directory
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

try {
    # Get Python
    $python = Get-Python

    # Get enrollment scripts
    $scriptDir = Get-EnrollmentScripts

    # Build arguments
    $args = @(
        "$scriptDir\install-minion.py",
        "--master", $Master,
        "--minion-id", $MinionId,
        "--roles", $Roles
    )

    if ($Force) {
        $args += "--force"
    }

    # Run installer
    Write-Host ""
    Write-Host "Running Python installer..."
    Write-Host ""

    & $python @args
    $exitCode = $LASTEXITCODE

    exit $exitCode
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}
finally {
    # Cleanup temp files (keep Python for future runs)
    # Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
}
