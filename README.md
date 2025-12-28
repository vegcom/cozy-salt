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
.\scripts\enrollment\install-win-minion.ps1 -Master $(wsl hostname -I)
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

**Windows:**
```
scripts/pxe/windows/
├── autounattend.xml      # Unattended Windows install
├── SetupComplete.ps1     # Auto-enrolls with Salt Master
└── README.md             # Detailed setup
```

**Linux:**
```
scripts/pxe/linux/
├── preseed.cfg           # Ubuntu/Debian automated install
├── kickstart.cfg         # RHEL/Rocky automated install
├── post-install.sh       # Auto-enrolls with Salt Master
└── README.md             # Detailed setup
```

1. Set up PXE server (WDS, FOG, netboot.xyz, or Cobbler)
2. Configure automated install files (preseed/kickstart/autounattend)
3. PXE boot new machines → auto-install → auto-enroll with Salt

See [`scripts/pxe/`](scripts/pxe/) for platform-specific details.

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
│   ├── salt/                    # Salt states (modular)
│   │   ├── top.sls              # State targeting
│   │   ├── windows/             # Windows states
│   │   │   ├── init.sls         # Orchestrator
│   │   │   ├── packages.sls    # Packages
│   │   │   ├── config.sls      # Configuration
│   │   │   ├── tasks.sls       # Scheduled tasks
│   │   │   └── services.sls    # Services
│   │   └── linux/               # Linux states
│   │       ├── init.sls         # Orchestrator
│   │       ├── packages.sls    # Packages
│   │       ├── config.sls      # Configuration
│   │       └── services.sls    # Services
│   └── pillar/                  # Configuration data
│       ├── win/init.sls         # Windows config
│       └── linux/init.sls       # Linux config
├── provisioning/
│   ├── windows/
│   │   ├── files/opt-cozy/      # PowerShell scripts
│   │   └── tasks/               # Scheduled tasks (XML)
│   ├── linux/                   # Shell scripts, dotfiles
│   ├── wsl/                     # WSL local dev setup
│   │   └── files/opt-cozy/
│   │       ├── bootstrap.sh     # One-shot setup
│   │       ├── docker.sh        # Install Docker
│   │       └── docker-proxy.yaml # Socket proxy
│   └── packages.sls             # Consolidated package list
├── scripts/
│   ├── docker/                  # Container entrypoints
│   ├── enrollment/              # Manual minion installation
│   │   └── install-win-minion.ps1
│   └── pxe/                     # Automated bare-metal deployment
│       ├── windows/             # Windows PXE
│       └── linux/               # Linux PXE (preseed, kickstart)
├── tests/                       # Linting tests
│   ├── test-shellscripts.sh
│   └── test-psscripts.ps1
├── Dockerfile.master
├── Dockerfile.linux-minion
└── docker-compose.yaml          # Use --profile test-linux for testing
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

- Hardened SSH configs deployed for all platforms (see SECURITY.md for production hardening)
- Pillar data may contain sensitive config - control access appropriately
- Review package lists before deploying to production

## Testing

```bash
# Test environment with Linux minion
docker compose --profile test-linux up -d

# Validate state syntax
docker compose exec salt-master salt-call --local state.show_sls windows
```

## License

MIT
