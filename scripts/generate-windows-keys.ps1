# generate-windows-keys.ps1
# Generates windows-test RSA keys for Salt enrollment
# These keys must match what's generated in the Dockerfile keygen stage

param(
    [string]$KeysDir = (Join-Path (Split-Path -Parent $PSScriptRoot) "scripts\pki\minion")
)

$ErrorActionPreference = "Stop"

Write-Host "=== Generating Windows Test Keys ===" -ForegroundColor Cyan
Write-Host "Keys directory: $KeysDir"

# Create directory if it doesn't exist
if (-not (Test-Path $KeysDir)) {
    Write-Host "Creating directory..." -ForegroundColor Green
    New-Item -ItemType Directory -Path $KeysDir -Force | Out-Null
}

# Check if keys already exist
if ((Test-Path (Join-Path $KeysDir "minion.pem")) -and (Test-Path (Join-Path $KeysDir "minion.pub"))) {
    Write-Host "✓ Keys already exist" -ForegroundColor Green
    Write-Host "  Path: $KeysDir"
    exit 0
}

# Generate RSA keys using openssl (must be installed)
Write-Host "Generating RSA key pair..." -ForegroundColor Green

try {
    $pemPath = Join-Path $KeysDir "minion.pem"
    $pubPath = Join-Path $KeysDir "minion.pub"

    # Generate private key
    Write-Host "  Generating private key..."
    & openssl genrsa -out $pemPath 4096 2>$null

    # Generate public key from private key
    Write-Host "  Generating public key..."
    & openssl rsa -in $pemPath -pubout -out $pubPath 2>$null

    Write-Host ""
    Write-Host "✓ Keys generated successfully" -ForegroundColor Green
    Write-Host "  - minion.pem"
    Write-Host "  - minion.pub"
    Write-Host ""
    Write-Host "Keys are ready for Docker mount at: $KeysDir"

} catch {
    Write-Error "Failed to generate keys: $_"
    Write-Host ""
    Write-Host "Ensure OpenSSL is installed and in PATH:" -ForegroundColor Yellow
    Write-Host "  Windows: choco install openssl"
    Write-Host "  Or: Download from https://slproweb.com/products/Win32OpenSSL.html"
    exit 1
}
