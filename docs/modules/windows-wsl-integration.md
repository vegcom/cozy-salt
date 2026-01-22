# WSL Integration Configuration

Windows Subsystem for Linux integration: Docker Desktop context configuration, WSL bridge setup.

## Location

- **State**: `srv/salt/windows/wsl-integration.sls`
- **Include**: `windows.init`

## Purpose

Bridge Windows and WSL environments:

- Docker context configuration
- WSL 2 Docker daemon access
- File sharing setup
- Network bridge configuration

## Configuration

Sets up Docker contexts for:

- Windows Docker Desktop
- WSL 2 Docker daemon (if available)
- Container filesystem sharing
- Network routing between systems

## Detection

Auto-detects:

- WSL presence
- WSL distribution names
- Docker Desktop installation
- Docker daemon version

## Docker Contexts

Creates contexts:

- `desktop-linux`: Windows Docker Desktop
- `wsl-ubuntu`: WSL Ubuntu Docker daemon
- `wsl-debian`: WSL Debian Docker daemon (if present)

## Usage

```cmd
docker context list          REM View available contexts
docker context use wsl-ubuntu REM Switch to WSL context
docker ps                    REM Works with WSL Docker
```

## Notes

- WSL 2 only (WSL 1 not supported)
- Requires Docker installed on both Windows and WSL
- File access from either system
- Network transparent between OS layers
