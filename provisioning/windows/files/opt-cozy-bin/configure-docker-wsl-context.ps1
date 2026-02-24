# configure-docker-wsl-context.ps1 - Windows Docker WSL integration
# Sets up Docker context to use WSL's Docker daemon via TCP proxy
# Managed by Salt - DO NOT EDIT MANUALLY

$ErrorActionPreference = "SilentlyContinue"

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { exit 0 }

$contextList = docker context ls --format "{{.Name}}" 2>$null
$hasContext = $contextList -split "`n" | Where-Object { $_ -eq "wsl" }

if (-not $hasContext) {
    docker context create wsl --docker "host=tcp://127.0.0.1:2375" 2>$null
}

docker context use wsl 2>$null
docker info 2>$null | Out-Null

if ($LASTEXITCODE -ne 0) {
    docker context use default 2>$null
    exit 1
}
