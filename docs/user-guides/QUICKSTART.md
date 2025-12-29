# Quick Start Guide

Get cozy-salt running in 3 main options.

## Option A: Full Setup (WSL + Windows)

WSL hosts Docker and the Salt Master. Windows connects as a minion.

**Step 1: Set up WSL**
```bash
# In WSL (Ubuntu recommended)
mkdir -p /opt/cozy && cd /opt/cozy
git clone <repository-url> cozy-salt
cd cozy-salt

# Copy setup scripts
cp provisioning/wsl/files/opt-cozy/* /opt/cozy/

# Run bootstrap (installs Docker, starts Salt Master)
chmod +x /opt/cozy/*.sh
/opt/cozy/bootstrap.sh
```

**Step 2: Set up Windows**
```powershell
# Run as Administrator
cd C:\path\to\cozy-salt

# Set up Docker context to use WSL
docker context create wsl --docker "host=tcp://localhost:2375"
docker context use wsl

# Install Salt Minion
.\scripts\enrollment\install-win-minion.ps1 -Master $(wsl hostname -I)
```

**Step 3: Accept & Apply**
```bash
# In WSL
docker exec salt-master salt-key -A    # Accept minion
docker exec salt-master salt '*' state.apply  # Apply states
```

## Option B: Standalone Salt Master

If you already have Docker running:

```bash
git clone <repository-url>
cd cozy-salt
docker compose up -d
```

Then install minions and apply states as shown above.

## Option C: PXE Deployment (Bare Metal)

For automated OS install + Salt enrollment via network boot:

See detailed guides:
- [Windows PXE Deployment](windows-pxe-deployment.md)
- [Linux PXE Deployment](linux-pxe-deployment.md)

## Prerequisites

- Docker & Docker Compose
- Git

No other dependencies. SaltStack runs in the container.

## Next Steps

- See [Testing Guides](../development/testing/) to test your setup
- See [Security Guide](../security/SECURITY.md) for production hardening
- See [Contributing Guide](../development/CONTRIBUTING.md) to get involved
