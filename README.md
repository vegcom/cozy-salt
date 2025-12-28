# cozy-salt

A SaltStack infrastructure-as-code project for provisioning and managing Windows, WSL, and Linux development environments. Automates installation and configuration of development tools, AI/ML frameworks, container orchestration, and more.

## Status: Production Ready

The core infrastructure is functional:
- Docker-based Salt Master
- Windows and Linux base states
- Pillar data for configuration
- Minion installer scripts
- Consolidated package lists

## Quick Start

### Option A: Full Setup (WSL + Windows)

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
.\scripts\install-win-minion.ps1 -Master $(wsl hostname -I)
```

**Step 3: Accept & Apply**
```bash
# In WSL
docker exec salt-master salt-key -A    # Accept minion
docker exec salt-master salt '*' state.apply  # Apply states
```

### Option B: Standalone Salt Master

If you already have Docker running:

```bash
git clone <repository-url>
cd cozy-salt
docker compose up -d
```

Then install minions and apply states as shown above.

### Option C: PXE Deployment (Bare Metal)

For automated OS install + Salt enrollment via network boot:

```
provisioning/windows/pxe/
├── autounattend.xml      # Unattended Windows install
├── SetupComplete.ps1     # Auto-enrolls with Salt Master
└── README.md             # Detailed setup for WDS/FOG/netboot
```

1. Set up PXE server (WDS, FOG, or netboot.xyz)
2. Add `autounattend.xml` to your Windows image
3. Include `SetupComplete.ps1` at `C:\Windows\Setup\Scripts\`
4. PXE boot new machines → auto-install → auto-enroll with Salt

See [`provisioning/windows/pxe/README.md`](provisioning/windows/pxe/README.md) for details.

## Architecture

### Production: Linux Server + Windows Minions

```
                        ┌─────────────────────┐
                        │   Linux Server      │
                        │  ┌───────────────┐  │
                        │  │  Salt Master  │  │
                        │  │  (Docker)     │  │
                        │  └───────┬───────┘  │
                        │      4505/4506      │
                        └──────────┼──────────┘
                                   │
        ┌──────────────────────────┼──────────────────────────┐
        │                          │                          │
        ▼                          ▼                          ▼
┌───────────────┐        ┌───────────────┐        ┌───────────────┐
│ Windows PC    │        │ Windows PC    │        │ Linux Server  │
│ (Salt Minion) │        │ (Salt Minion) │        │ (Salt Minion) │
└───────────────┘        └───────────────┘        └───────────────┘
```

### Development: WSL + Windows (Local)

```
┌─────────────────────────────────────────────────────────────┐
│                         WINDOWS                             │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────────┐  │
│  │ Salt Minion │───▶│ Docker CLI  │───▶│ WSL (port 2375) │  │
│  └─────────────┘    └─────────────┘    └────────┬────────┘  │
└────────────────────────────────────────────────┬────────────┘
                                                 │
┌────────────────────────────────────────────────▼────────────┐
│                          WSL                                │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                    Docker                            │   │
│  │  ┌─────────────┐    ┌─────────────┐                  │   │
│  │  │ Salt Master │    │ Socket Proxy│◀── TCP 2375      │   │
│  │  │  Container  │    │  (Traefik)  │                  │   │
│  │  └─────────────┘    └─────────────┘                  │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### Directory Structure

```
cozy-salt/
├── srv/
│   ├── salt/                    # Salt states
│   │   ├── top.sls              # State targeting
│   │   ├── windows/win.sls      # Windows provisioning
│   │   └── linux/base.sls       # Linux provisioning
│   └── pillar/                  # Configuration data
│       ├── win/init.sls         # Windows config
│       └── linux/init.sls       # Linux config
├── provisioning/
│   ├── windows/
│   │   ├── files/opt-cozy/      # PowerShell scripts
│   │   ├── tasks/               # Scheduled tasks (XML)
│   │   └── pxe/                 # PXE/WDS deployment
│   │       ├── autounattend.xml # Unattended install
│   │       └── SetupComplete.ps1 # Salt auto-enrollment
│   ├── linux/                   # Shell scripts, dotfiles
│   └── wsl/                     # WSL local dev setup
│       └── files/opt-cozy/
│           ├── bootstrap.sh     # One-shot setup
│           ├── docker.sh        # Install Docker
│           └── docker-proxy.yaml # Socket proxy
│   └── packages.sls             # Consolidated package list
├── scripts/install-win-minion.ps1
├── Dockerfile
└── docker-compose.yaml
```

## Package Management

Packages are consolidated in `provisioning/packages.sls`:

- **Chocolatey** (preferred): vim, Cygwin, docker-cli, docker-compose, dive, fonts
- **Winget**: Everything else (120+ packages categorized)

When duplicates exist, Chocolatey wins for better scripting support.

## What Gets Installed

### Windows
- Development: Git, Neovim, VS Code, Node.js (via NVM), Python (Miniconda/Miniforge)
- Containers: Docker CLI, kubectl, Helm, minikube
- AI/ML: Claude, Claude Code, LM Studio, Ollama integration
- Utilities: 7-Zip, PowerToys, Windows Terminal, Starship prompt
- Gaming: Steam, Playnite, controller support (DS4Windows, ViGEmBus)

### Linux
- Base packages: curl, wget, git, vim, htop, rsync
- Shell: Starship prompt with custom theme
- SSH on port 2222 (avoids conflict with Windows SSH on 22)
- Skeleton files for new users

## Configuration

### Pillar Data

Windows (`srv/pillar/win/init.sls`):
```yaml
cozy:
  base_path: 'C:\opt\cozy'
packages:
  manager: chocolatey
```

Linux (`srv/pillar/linux/init.sls`):
```yaml
cozy:
  base_path: '/opt/cozy'
ssh:
  port: 2222
```

## Prerequisites

- Docker & Docker Compose
- Git

No other dependencies. SaltStack runs in the container.

## Security Notes

- `provisioning/wsl/files/opt-cozy/docker.sh` exposes Docker on TCP 2375 (unencrypted) - use only in trusted networks
- Pillar data may contain sensitive config - control access appropriately
- Review package lists before deploying to production

## Testing

```bash
# Test environment with Linux minion
docker compose -f docker-compose.yaml -f docker-compose-test.yaml up -d

# Validate state syntax
docker compose exec salt-master salt-call --local state.show_sls windows.win
```

## License

MIT
