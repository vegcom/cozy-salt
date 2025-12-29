# configure-docker-wsl-context.ps1 - Windows Docker WSL integration
# Sets up Docker context to use WSL's Docker daemon via TCP proxy

$ErrorActionPreference = "SilentlyContinue"

Write-Host "=== Windows Provisioning ===" -ForegroundColor Cyan

# Check if Docker CLI is available (installed via Salt state)
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "Docker CLI not found. Run 'salt-call state.apply' first." -ForegroundColor Yellow
    exit 0
}

# Check if WSL context already exists
$existingContext = docker context ls --format "{{.Name}}" 2>$null | Where-Object { $_ -eq "wsl" }

if ($existingContext) {
    Write-Host "Docker context 'wsl' already exists" -ForegroundColor Green
} else {
    Write-Host "Creating Docker context 'wsl'..."
    docker context create wsl --docker "host=tcp://127.0.0.1:2375"
}

# Set as default
Write-Host "Setting 'wsl' as default Docker context..."
docker context use wsl

# Test connection
Write-Host ""
Write-Host "Testing Docker connection..." -ForegroundColor Cyan
$dockerInfo = docker info 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "Docker connection successful!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Docker is accessible via WSL at tcp://127.0.0.1:2375"
} else {
    Write-Host "Docker connection failed." -ForegroundColor Yellow
    Write-Host "Ensure WSL is running with Docker and the socket proxy:" -ForegroundColor Yellow
    Write-Host "  wsl -d Ubuntu" -ForegroundColor Gray
    Write-Host "  /opt/cozy/docker.sh" -ForegroundColor Gray
    Write-Host "  docker compose -f /opt/cozy/docker-proxy.yaml up -d" -ForegroundColor Gray
}

# Create done flag
$doneFlag = "C:\opt\cozy\.done.flag"
if (-not (Test-Path $doneFlag)) {
    New-Item -ItemType File -Path $doneFlag -Force | Out-Null
    Write-Host ""
    Write-Host "Provisioning complete. Flag created at $doneFlag" -ForegroundColor Green
}
