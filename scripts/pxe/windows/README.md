# Windows PXE Deployment with Salt Enrollment

This directory contains files for automated Windows deployment via PXE with automatic Salt Minion enrollment.

## Architecture

```
                                    ┌─────────────────────┐
                                    │   Linux Server      │
                                    │  ┌───────────────┐  │
                                    │  │  Salt Master  │  │
                                    │  │  (Docker)     │  │
                                    │  └───────┬───────┘  │
                                    │          │4505/4506 │
                                    └──────────┼──────────┘
                                               │
                    ┌──────────────────────────┼──────────────────────────┐
                    │                          │                          │
                    ▼                          ▼                          ▼
┌─────────────────────┐      ┌─────────────────────┐      ┌─────────────────────┐
│  Windows Workstation │      │  Windows Workstation │      │  Linux Server       │
│  (PXE deployed)      │      │  (PXE deployed)      │      │  (Salt Minion)      │
│  ┌─────────────┐     │      │  ┌─────────────┐     │      │  ┌─────────────┐    │
│  │ Salt Minion │     │      │  │ Salt Minion │     │      │  │ Salt Minion │    │
│  └─────────────┘     │      │  └─────────────┘     │      │  └─────────────┘    │
└─────────────────────┘      └─────────────────────┘      └─────────────────────┘

PXE Deployment Flow:
┌─────────────────┐     PXE Boot      ┌─────────────────┐
│   New Machine   │ ───────────────▶  │   PXE Server    │
│   (bare metal)  │                   │  (WDS/FOG/etc)  │
└────────┬────────┘                   └────────┬────────┘
         │                                     │
         │  1. Boot WinPE                      │
         │  2. Download install.wim            │
         │  3. Apply autounattend.xml          │
         ▼                                     │
┌─────────────────┐                           │
│ Windows Install │◀──────────────────────────┘
│ (unattended)    │
└────────┬────────┘
         │  4. First boot
         │  5. Run SetupComplete.ps1
         │  6. Install Salt Minion
         │  7. Connect to Salt Master
         ▼
┌─────────────────┐     4505/4506     ┌─────────────────┐
│  Salt Minion    │ ───────────────▶  │   Salt Master   │
│  (enrolled)     │                   │ (Linux Server)  │
└─────────────────┘                   └─────────────────┘
```

## Files

| File | Purpose |
|------|---------|
| `autounattend.xml` | Windows unattended install answer file |
| `SetupComplete.ps1` | Post-install script that installs Salt Minion |

## Setup Options

### Option 1: Windows Deployment Services (WDS)

Microsoft's built-in PXE server for Windows environments.

1. **Install WDS role** on Windows Server:
   ```powershell
   Install-WindowsFeature WDS -IncludeManagementTools
   ```

2. **Configure WDS**:
   - Open WDS console
   - Configure server (Respond to all computers)
   - Add boot image (boot.wim from Windows ISO)
   - Add install image (install.wim from Windows ISO)

3. **Add unattend file**:
   - Copy `autounattend.xml` to your deployment share
   - Associate with the install image in WDS

4. **Add SetupComplete.ps1**:
   - Include in the image or deploy via network share
   - Target location: `C:\Windows\Setup\Scripts\SetupComplete.ps1`

### Option 2: FOG Project (Free & Open Source)

Cross-platform imaging solution, great for mixed environments.

1. **Install FOG** on a Linux server:
   ```bash
   git clone https://github.com/FOGProject/fogproject.git
   cd fogproject/bin
   sudo ./installfog.sh
   ```

2. **Create Windows image**:
   - Install Windows with `autounattend.xml`
   - Sysprep: `sysprep /generalize /oobe /shutdown`
   - Capture image via FOG

3. **Deploy**:
   - PXE boot new machines
   - Select image in FOG menu
   - Salt enrollment happens on first boot

### Option 3: Netboot.xyz

Lightweight PXE boot menu for various OS installers.

1. **Set up netboot.xyz** as your PXE target
2. **Host Windows PE** + install files on HTTP server
3. **Include autounattend.xml** in the boot configuration

### Option 4: iPXE + Custom Script

For maximum flexibility:

```
#!ipxe
dhcp
set server http://your-server
kernel ${server}/wimboot
initrd ${server}/boot/bcd          BCD
initrd ${server}/boot/boot.sdi     boot.sdi
initrd ${server}/sources/boot.wim  boot.wim
boot
```

## Customization

### Automated Configuration (Recommended)

Use the `configure-autounattend.ps1` script to configure all variables at once:

```powershell
cd provisioning\windows\pxe
.\configure-autounattend.ps1 `
    -Username "admin" `
    -DisplayName "Admin User" `
    -Password "YourSecureP@ssw0rd!" `
    -SaltMaster "10.0.0.5"
```

This script will:
- Replace `{{USERNAME}}` and `{{DISPLAYNAME}}` placeholders in autounattend.xml
- Generate properly encoded passwords for all three password fields (Administrator, User, AutoLogon)
- Update the Salt Master default in SetupComplete.ps1
- Display a security checklist showing what was configured

**Parameters:**
- `-Username` - Local admin username (default: "cozy")
- `-DisplayName` - Display name for user (default: "Cozy Admin")
- `-Password` - Password for all accounts (default: "Admin@123" - **CHANGE THIS!**)
- `-SaltMaster` - Salt Master IP or hostname (default: "salt.example.com")
- `-InputFile` - Source XML file (default: "autounattend.xml")
- `-OutputFile` - Output XML file (default: "autounattend.xml" - overwrites)

**Example with all parameters:**
```powershell
.\configure-autounattend.ps1 `
    -Username "sysadmin" `
    -DisplayName "System Administrator" `
    -Password "C0mpl3x!P@ssw0rd#2024" `
    -SaltMaster "salt.example.com" `
    -InputFile "autounattend.xml" `
    -OutputFile "autounattend-customized.xml"
```

**Security Warning:** The default password is "Admin@123" - always set a strong custom password before deployment!

### Manual Configuration (Advanced)

If you need to manually configure individual settings:

#### 1. Set Salt Master Address

Edit `SetupComplete.ps1` or set via environment:

```powershell
# In SetupComplete.ps1, change:
[string]$Master = "your-salt-master-ip"

# Or set environment variable before running:
$env:SALT_MASTER = "192.168.1.100"
```

#### 2. Change Admin Password

In `autounattend.xml`, the password is Base64 encoded with a suffix. Generate new:

```powershell
# For Administrator account (uses "AdministratorPassword" suffix)
$password = "YourSecurePassword"
[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($password + "AdministratorPassword"))

# For User/AutoLogon accounts (uses "Password" suffix)
[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($password + "Password"))
```

**Note:** You must update three password fields in autounattend.xml:
1. `<AdministratorPassword>` - Built-in Administrator account (uses "AdministratorPassword" suffix)
2. `<LocalAccount><Password>` - Your custom user account (uses "Password" suffix)
3. `<AutoLogon><Password>` - Auto-login password (uses "Password" suffix)

The configure-autounattend.ps1 script handles all three automatically.

#### 3. Change Locale/Timezone

Edit the `Microsoft-Windows-International-Core-WinPE` and `TimeZone` sections.

#### 4. Disk Layout

The default is UEFI GPT with:
- 512MB EFI partition
- 128MB MSR partition
- Rest for Windows (C:)

For BIOS/MBR, modify the `DiskConfiguration` section.

## Deployment Workflow

### Pre-deployment

1. **Deploy Salt Master** on your Linux server:
   ```bash
   git clone <repository-url> /opt/cozy-salt
   cd /opt/cozy-salt
   docker compose up -d
   ```

2. **Note the Salt Master IP/hostname**:
   ```bash
   hostname -I | awk '{print $1}'
   # Or use DNS: salt.example.com
   ```

3. **Update SetupComplete.ps1** with the Salt Master address:
   ```powershell
   [string]$Master = "salt.example.com"  # or IP address
   ```

### Deployment

1. **PXE boot** the new machine
2. **Windows installs** automatically (15-30 minutes)
3. **First boot** runs SetupComplete.ps1
4. **Salt Minion** installs and connects to master

### Post-deployment

On your Linux Salt Master server:

1. **Accept the minion key**:
   ```bash
   docker exec salt-master salt-key -L    # List pending
   docker exec salt-master salt-key -A    # Accept all
   ```

2. **Verify connection**:
   ```bash
   docker exec salt-master salt '*' test.ping
   ```

3. **Apply states**:
   ```bash
   docker exec salt-master salt '*' state.apply
   ```

### Auto-accept Keys (Optional)

For fully automated enrollment, configure the Salt Master to auto-accept keys.
Add to `srv/salt/master.d/auto-accept.conf`:
```yaml
auto_accept: True
# Or use reactor for more control
```

**Security Note**: Only use auto-accept in trusted networks.

## Troubleshooting

### Minion not appearing

Check logs on the Windows machine:
```powershell
Get-Content C:\Windows\Temp\salt-enrollment.log
Get-Content C:\salt\var\log\salt\minion
```

### Network issues

Ensure ports are open:
- 4505/tcp - Salt Master publish port
- 4506/tcp - Salt Master return port

### Salt version issues

The script tries multiple download sources. If all fail, it falls back to Chocolatey:
```powershell
choco install saltminion -y
```

## Security Notes

1. **Change default passwords** in autounattend.xml before deployment
2. **Use HTTPS** for Salt Master if possible
3. **Firewall rules** should restrict Salt ports to trusted networks
4. **Consider disk encryption** (BitLocker) for sensitive environments

## References

- [Salt Windows Installation](https://docs.saltproject.io/salt/install-guide/en/latest/topics/install-by-operating-system/windows.html)
- [Windows Unattend Reference](https://learn.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/)
- [FOG Project](https://fogproject.org/)
- [WDS Documentation](https://learn.microsoft.com/en-us/windows/deployment/wds-boot-support)
