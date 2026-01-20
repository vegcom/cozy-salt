# Windows Minion Auto-Enrollment (Dockur)

This document describes how the Windows test minion (via Dockur) auto-enrolls in Salt, mirroring the behavior of Ubuntu and RHEL test minions.

## Overview

The Windows minion uses **Dockur** (QEMU-based Windows container) with:

- **Unattended Windows 11 installation** via `Autounattend.xml`
- **FirstLogonCommands** running an enrollment script on first admin login
- **Pre-shared RSA keys** mounted from host for immediate authentication
- **Automatic `state.highstate`** after master connection

## Architecture

### Components

1. **Dockerfile (keygen stage)**
   - Generates `windows-test.pem` and `windows-test.pub` at build time
   - Same as `ubuntu-test` and `rhel-test` keys
   - Copied to master's minions-preload directory

2. **Autounattend.xml** (`provisioning/windows/Autounattend.xml`)
   - Windows unattended installation configuration
   - Skips OOBE (Out-of-Box Experience)
   - Creates local admin account (`admin`/`admin123!`)
   - Runs `entrypoint-minion.ps1` via FirstLogonCommands

3. **Enrollment Script** (`scripts/docker/entrypoint-minion.ps1`)
   - Runs as SYSTEM from FirstLogonCommands
   - Waits for network connectivity
   - Copies pre-shared keys from mounted `/mnt/scripts`
   - Installs Salt minion (v3007.10)
   - Configures minion with pre-shared keys
   - Connects to `salt-master`
   - Auto-runs `state.highstate`

4. **Key Generation** (`scripts/generate-windows-keys.sh` / `.ps1`)
   - Generates `windows-test.pem` and `.pub` keys
   - Places them at `scripts/pki/minion/` for Docker mount
   - Cross-platform (bash on Unix, PowerShell on Windows)

5. **Docker Compose Volume Mounts**
   ```yaml
   volumes:
     - ./scripts:/mnt/scripts:ro # Scripts + keys
     - ./provisioning/windows/Autounattend.xml:/Autounattend.xml:ro
   ```

## How It Works

### 1. Build Phase

```bash
docker compose build
```

- Keygen stage generates `windows-test.{pem,pub}`
- Keys are copied into master image at `/etc/salt/pki/master/minions-preload/`
- Master's entrypoint pre-accepts all keys from preload directory

### 2. Key Setup Phase

```bash
make setup-windows-keys
# or (on Windows): pwsh -ExecutionPolicy Bypass -File scripts/generate-windows-keys.ps1
```

- Generates keys at `scripts/pki/minion/minion.{pem,pub}`
- Keys must exist before starting Dockur for mounting

### 3. Container Startup Phase

```bash
make up-windows-test
```

- Starts master (if not running)
- Generates keys (if needed)
- Starts Dockur Windows container with:
  - `MANUAL=N` (unattended install)
  - Mounted `/Autounattend.xml`
  - Mounted `/mnt/scripts` (contains enrollment script + keys)

### 4. Windows Boot Phase

- QEMU boots Windows 11
- Runs unattended setup with Autounattend.xml
- Automatically logs in as admin
- FirstLogonCommands executes `entrypoint-minion.ps1`

### 5. Enrollment Phase

```powershell
# entrypoint-minion.ps1 runs as SYSTEM:

# 1. Wait for network (up to 5 minutes)
# 2. Wait for mounted keys at D:\scripts\pki\minion\ (up to 2 minutes)
# 3. Download & install Salt Minion v3007.10
# 4. Create C:\opt\salt\conf\minion.d\99-custom.conf with:
#    - master: salt-master
#    - id: windows-test
#    - grains.roles: [workstation]
# 5. Copy pre-shared keys to C:\opt\salt\conf\pki\minion\
# 6. Start salt-minion service
# 7. Wait for master connectivity (salt-call test.ping returns True)
# 8. Run state.highstate
```

### 6. Ready for Management

- Minion is registered as `windows-test`
- Master has pre-accepted the key
- Can receive Salt commands immediately
- Fully provisioned on first boot

## Quick Start

### Linux/macOS

```bash
# 1. Build Docker image (generates all keys including windows-test)
docker compose build

# 2. Generate windows-test keys for mounting
make setup-windows-keys

# 3. Start master
make up-master

# 4. Start Windows test minion (auto-enrolls)
make up-windows-test

# Wait ~15 minutes for Windows to boot + install Salt + run highstate
# Then:
docker compose exec -t salt-master salt 'windows-test' test.ping
```

### Windows (PowerShell)

```powershell
# 1. Build Docker image
docker compose build

# 2. Generate keys
pwsh -ExecutionPolicy Bypass -File scripts/generate-windows-keys.ps1

# 3. Start master and Windows minion
docker compose up -d salt-master
docker compose --profile test-windows up -d salt-minion-windows

# Wait ~15 minutes
# Then:
docker compose exec -t salt-master salt 'windows-test' test.ping
```

## Accessing the Windows Container

### Via Web VNC

- URL: `http://localhost:8006`
- Credentials: `admin` / `admin123!` (local account created by Autounattend.xml)

### Via RDP

```bash
# From Linux/macOS:
rdesktop -u admin -p admin123! localhost:3389

# Or use Windows RDP client:
# Server: localhost:3389
# Username: admin
# Password: admin123!
```

## Key Files

| File                                    | Purpose                                            |
| --------------------------------------- | -------------------------------------------------- |
| `Dockerfile`                            | Keygen stage generates windows-test RSA keys       |
| `docker-compose.yaml`                   | Dockur service config with mounts + MANUAL=N       |
| `provisioning/windows/Autounattend.xml` | Windows unattended setup + FirstLogonCommands      |
| `scripts/docker/entrypoint-minion.ps1`  | Salt enrollment script (runs on first boot)        |
| `scripts/generate-windows-keys.sh`      | Generate keys (bash)                               |
| `scripts/generate-windows-keys.ps1`     | Generate keys (PowerShell)                         |
| `scripts/pki/minion/`                   | Pre-shared key storage for Docker mount            |
| `Makefile`                              | `make up-windows-test` / `make setup-windows-keys` |

## Troubleshooting

### Keys Not Found in Enrollment Script

- Run `make setup-windows-keys` to generate keys
- Verify `scripts/pki/minion/minion.{pem,pub}` exist
- Check docker-compose.yaml volume mounts are correct

### Windows Takes 20+ Minutes to Boot

- First boot downloads Windows 11 ISO (~4GB) - normal
- Subsequent boots are much faster
- Check disk space: `docker system df`
- Free up space if needed: `docker system prune -a --volumes`

### Enrollment Script Doesn't Run

- Check Dockur logs: `docker logs salt-minion-windows-test`
- Verify Autounattend.xml is readable at `/Autounattend.xml`
- Check FirstLogonCommands path: `C:\scripts\scripts\docker\entrypoint-minion.ps1`

### Salt Minion Installation Fails

- Verify network connectivity in Windows (ping 8.8.8.8)
- Check `C:\opt\salt\var\log\salt\minion` logs
- Verify download URL is accessible: `https://packages.broadcom.com/artifactory/saltproject-generic/windows/3007.10/...`

### Minion Not Connecting to Master

- Verify master is running: `docker compose ps`
- Check minion config: `C:\opt\salt\conf\minion.d\99-custom.conf`
- Verify master hostname resolution: `ping salt-master` from Windows
- Check master logs: `docker compose logs salt-master | grep windows-test`

### Pre-Shared Keys Not Copied

- Verify keys are mounted: Check if `D:\scripts\pki\minion\minion.pem` exists in running Windows
- Run `dir D:\scripts` to list mount contents
- If missing, check docker-compose.yaml volumes section
- May be mounted at different drive letter (E:\ or \\10.0.2.4\) - enrollment script tries all

## Performance Notes

- **First boot**: 15-20 minutes (downloads ISO + Windows boot + Salt install)
- **Subsequent boots**: 3-5 minutes (cached ISO)
- **Highstate on first boot**: Depends on number of states (typically 2-5 minutes)
- **CPU usage**: Peaks at 160% during installation
- **Memory usage**: ~4GB allocated, typically uses 1.5-2.5GB
- **Disk usage**: 64GB virtual disk, typically uses 30-40GB after first boot

## Comparison with Other Test Minions

| Aspect         | Ubuntu          | RHEL            | Windows                              |
| -------------- | --------------- | --------------- | ------------------------------------ |
| Container Type | Docker          | Docker          | Dockur (KVM)                         |
| Boot Time      | ~2 min          | ~2 min          | ~10 min (first), ~3 min (subsequent) |
| Salt Keys      | Baked in image  | Baked in image  | Pre-shared mount                     |
| Enrollment     | Auto on startup | Auto on startup | Auto on first login                  |
| Access         | Shell/exec      | Shell/exec      | Web VNC / RDP                        |
| KVM Required   | No              | No              | Yes (Linux host only)                |

## Related Documentation

- [Salt Windows Module Reference](https://docs.saltproject.io/en/latest/topics/windows/index.html)
- [Dockur Documentation](https://github.com/dockur/windows)
- [Salt Installation Guide](https://docs.saltproject.io/salt/install-guide/en/latest/topics/install-by-operating-system/windows.html)
- [Autounattend.xml Reference](https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/)
