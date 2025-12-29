# Linux PXE Deployment

Automated bare-metal Linux deployment with Salt auto-enrollment.

## Overview

PXE boot → Automated OS install → Salt minion enrollment → Highstate applied

Supports:
- **Ubuntu/Debian**: preseed.cfg
- **RHEL/Rocky/Alma**: kickstart.cfg

## Quick Start

### 1. Configure PXE Server

Choose your PXE server (examples for netboot.xyz, but works with any):

**netboot.xyz / iPXE:**
```
#!ipxe
kernel http://archive.ubuntu.com/ubuntu/dists/jammy/main/installer-amd64/current/legacy-images/netboot/ubuntu-installer/amd64/linux
initrd http://archive.ubuntu.com/ubuntu/dists/jammy/main/installer-amd64/current/legacy-images/netboot/ubuntu-installer/amd64/initrd.gz
imgargs linux auto=true priority=critical url=http://your-server/preseed.cfg salt_master=salt-master-ip
boot
```

**FOG Server:**
- Upload Ubuntu/Rocky ISO
- Add preseed.cfg or kickstart.cfg to HTTP server
- Set kernel parameters for automated install

**Cobbler:**
```bash
cobbler profile add --name=ubuntu-salt --distro=ubuntu-22.04 \
  --kickstart=http://your-server/preseed.cfg \
  --kopts="salt_master=10.0.0.10"
```

### 2. Host Configuration Files

Place these files on a web server accessible during install:

```
http://your-server/salt-pxe/
├── preseed.cfg      # For Ubuntu/Debian
├── kickstart.cfg    # For RHEL/Rocky
└── post-install.sh  # Salt enrollment
```

### 3. Boot Target Machine

- PXE boot the machine
- Installer downloads preseed/kickstart
- OS installs automatically
- post-install.sh runs and enrolls with Salt Master
- System applies highstate and is ready

## Configuration

### preseed.cfg (Ubuntu/Debian)

Key variables to customize:
- Line 7: `d-i mirror/http/hostname` - Ubuntu mirror
- Line 25: `d-i partman-auto/disk` - Target disk (default: /dev/sda)
- Line 59: `SALT_MASTER` in late_command - Your Salt Master IP/hostname

### kickstart.cfg (RHEL/Rocky)

Key variables to customize:
- Line 3: `url --url` - Installation source
- Line 11: `clearpart --drives=sda` - Target disk
- Line 46: `SALT_MASTER` in %post - Your Salt Master IP/hostname

### post-install.sh

Reads `SALT_MASTER` from kernel parameter or environment variable:
```bash
# Pass via kernel parameter:
salt_master=10.0.0.10

# Or set in preseed/kickstart:
export SALT_MASTER=salt-master.example.com
```

## Security Notes

- **Auto-accept keys**: Edit post-install.sh to use pre-shared keys for production
- **HTTP vs HTTPS**: Use HTTPS for config files in production
- **Credentials**: preseed/kickstart contain root password hash - protect these files

## Troubleshooting

**Install fails to download preseed/kickstart:**
- Verify web server is accessible from installer network
- Check URL in kernel parameters

**Salt minion doesn't connect:**
- Check SALT_MASTER variable is set correctly
- Verify Salt Master ports 4505/4506 are accessible
- Check `/var/log/salt/minion` on the target system

**Partitioning fails:**
- Verify target disk name (may be /dev/nvme0n1 instead of /dev/sda)
- Adjust preseed.cfg or kickstart.cfg accordingly

## Testing

Test in a VM before bare metal:
```bash
# Create VM, set to PXE boot
qemu-system-x86_64 -m 2048 -boot n -netdev user,id=net0 \
  -device e1000,netdev=net0 -hda disk.img
```
