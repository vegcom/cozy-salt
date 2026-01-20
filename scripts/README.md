# Scripts Documentation

This directory contains utility scripts for Salt master/minion setup, enrollment, and maintenance.

## Directory Structure

```
scripts/
├── docker/               Container initialization scripts
│   ├── entrypoint-master.sh
│   └── entrypoint-minion.sh
├── enrollment/           Manual system provisioning scripts
│   ├── install-linux-minion.sh
│   ├── install-windows-minion.ps1
│   └── entrypoint-minion.ps1
├── fix-permissions.sh    Permission management utility
├── generate-windows-keys.sh & .ps1  Key generation utilities
└── pki/                  Generated at runtime (see below)
```

## Scripts by Category

### Docker Entrypoints

**`docker/entrypoint-master.sh`**

- Purpose: Initialize Salt master in Docker container
- Pre-accepts all pending minion keys
- Starts Salt master daemon in foreground
- Used by: `docker-compose.yaml` (master service)
- Requires: Pre-shared minion keys in `/etc/salt/pki/master/minions/`

**`docker/entrypoint-minion.sh`**

- Purpose: Initialize Salt minion in Docker container
- Loads pre-shared master and minion keys
- Starts minion daemon and immediately applies highstate
- Used by: `docker-compose.yaml` (ubuntu, rhel services)
- Requires: Pre-shared keys in `/etc/salt/pki/minion/`
- Exit code: 0 if highstate succeeds, non-zero otherwise

### Enrollment Scripts

These scripts enroll existing systems (not in containers) as Salt minions.

**`enrollment/install-linux-minion.sh`**

- Purpose: Provision existing Linux systems as Salt minions
- Auto-detects OS: Ubuntu, Debian, RHEL, CentOS, Fedora
- Installs Salt minion package from official repos
- Configures `/etc/salt/minion` with master address
- Usage:
  ```bash
  curl https://your-repo/scripts/enrollment/install-linux-minion.sh | sudo bash
  ```
- Requirements: Sudo access, internet connectivity
- Sets master address (default: `salt.local`)

**`enrollment/install-windows-minion.ps1`**

- Purpose: Provision existing Windows systems as Salt minions
- Downloads Salt MSI installer from GitHub releases
- Installs to `C:\Program Files\Salt Project\Salt`
- Registers as Windows service (starts on boot)
- Usage (PowerShell as Admin):
  ```powershell
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
  Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://your-repo/scripts/enrollment/install-windows-minion.ps1')
  ```
- Requirements: PowerShell 5.0+, Admin privileges, internet
- Restarts Salt minion service after installation

**`enrollment/entrypoint-minion.ps1`**

- Purpose: First-boot provisioning for Windows VMs (Dockur-specific)
- Runs as SYSTEM during initial Windows setup (via Autounattend.xml)
- Waits for network connectivity
- Waits for master to be reachable
- Downloads and installs Salt minion
- Applies initial highstate
- **Only used in Dockur virtualization context**, not for regular Windows machines
- See: `provisioning/windows/Autounattend.xml` for integration

### Utilities

**`fix-permissions.sh`**

- Purpose: Ensure correct file permissions for Salt deployment
- Sets 644 on configuration files (.sls, .yml, .yaml)
- Sets 755 on executable scripts (.sh)
- Sets 755 on executable provisioning scripts in `provisioning/`
- Usage: `./scripts/fix-permissions.sh`
- Safety: Idempotent - safe to run repeatedly
- Automation: Runs automatically via pre-commit hook
- Related: `make perms` target

**`generate-windows-keys.sh` & `generate-windows-keys.ps1`**

- Purpose: Generate RSA key pairs for Windows Salt minion
- Both scripts do the same thing in different languages (bash/PowerShell)
- Creates key pair: `scripts/pki/minion/{minion.pem, minion.pub}`
- Usage:
  ```bash
  ./scripts/generate-windows-keys.sh  # or PowerShell version
  ```
- Used by: `make setup-windows-keys` target
- Context: Keys mounted in Dockur Windows VM to pre-authenticate

## Integration with Build System

### Makefile Targets

- `make setup-windows-keys` → Runs key generation script
- `make perms` → Runs `fix-permissions.sh`
- `make validate` → Validates scripts (linting)
- `make lint-shell` → ShellCheck validation
- `make lint-ps` → PowerShell linting
- `make test-*` → Runs enrollment scripts in containers

### Docker Integration

Scripts are mounted into containers via `docker-compose.yaml`:

```yaml
volumes:
  - ./scripts:/scripts:ro
  - ./provisioning:/provisioning:ro
```

- `scripts/` is read-only in containers
- Enrollment scripts run during `make test-windows` to verify functionality
- Entrypoint scripts run at container startup

## Adding New Scripts

### When to Create a Script

Add a script when you need to:

1. Initialize containers (place in `docker/`)
2. Provision new systems manually (place in `enrollment/`)
3. Perform maintenance tasks (place in root `scripts/`)
4. Generate certificates/keys (place in root `scripts/`)

### Script Guidelines

1. **Shebang**: Use `#!/usr/bin/env bash` (portable)
2. **Error handling**: Use `set -uo pipefail` for bash scripts
3. **Documentation**: Include header comment explaining purpose
4. **Logging**: Use color output for readability (see `fix-permissions.sh`)
5. **Exit codes**: Return 0 on success, non-zero on failure
6. **Idempotency**: When possible, make scripts safe to run repeatedly
7. **Portability**: Test across supported OS versions
8. **Permissions**: Run `./scripts/fix-permissions.sh` before committing

### File Naming

- Shell scripts: `.sh` extension
- PowerShell scripts: `.ps1` extension
- Executable scripts: Permissions 755
- Config files: Permissions 644

### Testing New Scripts

```bash
# Run linting
make lint-shell      # For .sh scripts
make lint-ps         # For .ps1 scripts

# Run fix-permissions
./scripts/fix-permissions.sh

# Commit
git add scripts/
git commit -m "feat: Add new script description"
```

## PKI Directory

### pki/minion/ (Runtime Generated)

- **Path**: `scripts/pki/minion/`
- **Contents**: `minion.pem`, `minion.pub` (RSA key pair)
- **Generation**: Created by `make setup-windows-keys`
- **Purpose**: Pre-authenticate Windows VMs with Salt master
- **Lifecycle**: Generated fresh for each test cycle
- **In .gitignore**: Yes (not version controlled)
- **Docker mount**: Mounted into Dockur Windows VM at boot time

## Architecture Notes

### Linux vs Windows Provisioning

**Linux** (`install-linux-minion.sh`):

- Installs from official package repos
- Simple package manager integration
- No extra bootstrapping needed

**Windows** (`install-windows-minion.ps1` and `entrypoint-minion.ps1`):

- Downloads MSI installer
- `entrypoint-minion.ps1` is Dockur-specific (VM first-boot)
- `install-windows-minion.ps1` is for manual installation on existing Windows

### Orchestration Flow

1. **Development**: `make up` starts containers
   - Entrypoint scripts run automatically
   - Salt master accepts keys pre-configured
   - Minions apply highstate

2. **Testing**: `make test-windows` or `make test-linux`
   - Enrollment scripts run to provision systems
   - Verifies scripts work on fresh systems
   - Tests both container and manual installation paths

3. **Production**: Manual enrollment
   - User downloads and runs appropriate enrollment script
   - System configures itself to connect to master
   - Applies initial state

## Related Documentation

- **Docker setup**: See `docker-compose.yaml` and Docker entrypoint usage
- **Windows enrollment**: See `scripts/enrollment/WINDOWS.md` for complete flow
- **File permissions**: See `scripts/fix-permissions.sh` comments
- **Salt configuration**: See `srv/salt/` and `srv/pillar/`
