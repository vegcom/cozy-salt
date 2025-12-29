# Local Windows Testing Setup with Dockur

This guide helps you set up local Windows testing using the Dockur Windows container (actual Windows 11 Desktop running in Docker via KVM).

## Prerequisites

### 1. Verify KVM Support

```bash
# Install KVM checker
sudo apt-get update
sudo apt-get install -y cpu-checker qemu-kvm

# Check if KVM is supported
kvm-ok
```

**Expected output:** `KVM acceleration can be used`

**If it fails:**
- Check BIOS/UEFI: Enable Intel VT-x or AMD-V
- Check if nested virtualization is enabled (if running in a VM)
- Verify CPU supports virtualization: `grep -E 'vmx|svm' /proc/cpuinfo`

### 2. Load KVM Modules

```bash
# Load kernel modules
sudo modprobe kvm
sudo modprobe kvm_intel  # Or kvm_amd for AMD CPUs

# Verify modules loaded
lsmod | grep kvm
```

### 3. Configure User Permissions

```bash
# Add your user to kvm group
sudo usermod -aG kvm $USER

# Apply group changes (logout/login or use newgrp)
newgrp kvm

# Verify group membership
groups | grep kvm
```

### 4. Verify Required Devices

```bash
# Check device files exist and are accessible
ls -la /dev/kvm /dev/net/tun

# Should show:
# crw-rw---- 1 root kvm  10, 232 ... /dev/kvm
# crw-rw-rw- 1 root root 10, 200 ... /dev/net/tun
```

**If /dev/kvm doesn't exist:**
```bash
# Create manually (usually automatic)
sudo mknod /dev/kvm c 10 232
sudo chmod 660 /dev/kvm
sudo chown root:kvm /dev/kvm
```

## Quick Start

### 1. Start Windows Test Container

```bash
cd /path/to/cozy-salt

# Create storage directory
mkdir -p windows-test

# Start Windows container (first run takes 5-10 minutes to install Windows)
docker compose --profile test-windows up -d
```

### 2. Access Windows via Web Interface

```bash
# Open in browser
xdg-open http://localhost:8006  # Or manually browse to http://localhost:8006
```

**Default credentials:**
- Username: `Docker`
- Password: `admin`

**First boot:**
- Windows 11 Pro will auto-install (5-10 minutes)
- Progress shown in web interface
- Auto-login after installation completes

### 3. Install Salt Minion in Windows

**Option A: Manual install via web interface**

1. In the Windows web interface, open PowerShell as Administrator
2. Download and run the install script:
   ```powershell
   # Access mounted scripts directory
   cd C:\mnt\scripts\enrollment

   # Run installer
   .\install-windows-minion.ps1 -Master salt-master -MinionId windows-test
   ```

**Option B: Access via RDP** (if you prefer native Windows experience)

```bash
# Connect via RDP client
remmina rdp://localhost:3389
# Or: xfreerdp /v:localhost:3389 /u:Docker /p:admin
```

### 4. Accept Minion Key on Master

```bash
# On Salt Master
docker exec salt-master salt-key -L

# Accept the Windows minion
docker exec salt-master salt-key -a windows-test
```

### 5. Test States

```bash
# Test connectivity
docker exec salt-master salt 'windows-test' test.ping

# Apply states
docker exec salt-master salt 'windows-test' state.apply

# View results
docker exec salt-master salt 'windows-test' state.apply --out=json | python3 tests/parse-state-results.py
```

## Troubleshooting

### KVM Permission Denied

**Symptom:** `Error: Could not access KVM kernel module: Permission denied`

**Fix:**
```bash
# Verify you're in kvm group
groups | grep kvm

# If not, add yourself and re-login
sudo usermod -aG kvm $USER
# Then logout and login again

# Temporary fix (until logout):
newgrp kvm
docker compose --profile test-windows up -d
```

### Windows Install Hangs

**Symptom:** Web interface shows loading screen for >15 minutes

**Fix:**
```bash
# Check container logs
docker logs salt-minion-windows-test

# Restart container
docker compose --profile test-windows restart

# If still hanging, try manual mode
# Edit docker-compose.yaml and uncomment: MANUAL: "N"
```

### Container Won't Start

**Symptom:** `Error response from daemon: error gathering device information`

**Fix:**
```bash
# Verify devices exist
ls -la /dev/kvm /dev/net/tun

# Verify Docker can access them
docker run --rm --device=/dev/kvm alpine ls -la /dev/kvm

# Check container logs
docker compose --profile test-windows logs
```

### Salt Minion Can't Connect

**Symptom:** Minion key not showing up on master

**Fix:**
```bash
# Verify network connectivity from Windows
# In Windows PowerShell:
Test-NetConnection salt-master -Port 4505
Test-NetConnection salt-master -Port 4506

# Check Windows firewall isn't blocking
# Check minion logs: C:\salt\var\log\salt\minion

# Verify master is reachable by hostname
ping salt-master
```

## Performance Tuning

### Adjust Resources

Edit `docker-compose.yaml`:

```yaml
environment:
  RAM_SIZE: "8G"       # Increase from 4G for better performance
  CPU_CORES: "4"       # Increase from 2 for faster builds
  DISK_SIZE: "128G"    # Increase from 64G if needed
```

### Use Pre-Built Image (Advanced)

After first successful setup, save the Windows image:

```bash
# Commit running container to image
docker commit salt-minion-windows-test cozy-salt-windows:latest

# Update docker-compose.yaml to use saved image:
# image: cozy-salt-windows:latest
# (instead of dockurr/windows)
```

**Benefits:**
- Faster startup (~1 min instead of 10 min)
- Salt already installed
- Pre-configured

## CI/CD Integration

### GitHub Actions Self-Hosted Runner

GitHub Actions doesn't support nested virtualization, so you'll need a self-hosted runner:

1. Set up Linux server with KVM support
2. Install GitHub Actions runner
3. Use same docker-compose setup

**.github/workflows/test-windows.yml:**
```yaml
name: Test Windows States

on: [push, pull_request]

jobs:
  test-windows:
    runs-on: self-hosted  # Requires self-hosted runner with KVM

    steps:
      - uses: actions/checkout@v4

      - name: Start Windows test environment
        run: docker compose --profile test-windows up -d

      - name: Wait for Windows ready
        run: sleep 300  # Wait 5 min for Windows to boot

      - name: Run states
        run: |
          docker exec salt-master salt 'windows-test' state.apply
          docker exec salt-master salt 'windows-test' state.apply  # Idempotency test

      - name: Cleanup
        if: always()
        run: docker compose --profile test-windows down
```

## Resource Requirements

### Minimum

- CPU: 2 cores with VT-x/AMD-V
- RAM: 6GB (4GB for Windows + 2GB for host)
- Disk: 80GB free
- Network: Stable internet for Windows ISO download (7.2GB)

### Recommended

- CPU: 4+ cores
- RAM: 12GB+ (8GB for Windows + 4GB for host)
- Disk: 150GB+ SSD
- Network: Fast connection for ISO download

## Next Steps

1. **Automate Salt installation:** Create startup script that auto-installs Salt minion
2. **Unattended Windows install:** Use Autounattend.xml for fully automated setup
3. **Pre-build images:** Save configured Windows images to skip installation time
4. **CI/CD pipeline:** Set up self-hosted runner for automated testing

See `TODO.md` for detailed implementation plan.
