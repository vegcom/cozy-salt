# PXE Deployment (Experimental)

Automated bare-metal deployment with Salt auto-enrollment.

**Status**: Untested - PXE enrollment workflow has not been verified. Use with caution.

## Overview

PXE boot → Automated OS install → Salt minion enrollment → Highstate applied

## Structure

```
pxe/
├── linux/
│   ├── kickstart.cfg      # RHEL/Rocky automated install
│   ├── preseed.cfg        # Ubuntu/Debian automated install
│   └── post-install.sh    # Salt enrollment script
└── windows/
    ├── autounattend.xml   # Windows unattended install
    ├── SetupComplete.ps1  # Post-install Salt enrollment
    └── configure-autounattend.ps1  # Configuration helper
```

## Linux Deployment

**Supports:** Ubuntu, Debian, RHEL, Rocky, Alma

1. Host preseed.cfg or kickstart.cfg on HTTP server
2. Configure PXE server to pass URL to installer
3. Set `salt_master` kernel parameter
4. Boot target machine
5. post-install.sh enrolls with Salt Master

**Key files to customize:**
- preseed.cfg: Mirror, disk, Salt Master IP
- kickstart.cfg: Installation source, disk, Salt Master IP
- post-install.sh: Kernel parameter parsing

## Windows Deployment

**Supports:** Windows Server 2019+, Windows 10/11

1. Set up PXE server (WDS, FOG, iPXE)
2. Configure autounattend.xml (password, Salt Master IP)
3. Boot target machine
4. SetupComplete.ps1 runs post-install, enrolls with Salt Master

**Configuration helper:**
```powershell
.\configure-autounattend.ps1 -SaltMaster "10.0.0.5" -Password "secure123"
```

## Next Steps

- [ ] Test Linux kickstart/preseed workflow end-to-end
- [ ] Test Windows WDS/FOG deployment end-to-end
- [ ] Document actual issues encountered
- [ ] Verify Salt enrollment happens automatically
- [ ] Test with multiple target systems

## Security Notes

- Pre-shared keys recommended (auto-accept not used)
- Change default passwords before deployment
- Use HTTPS for config files in production
- Restrict Salt ports (4505/4506) to trusted networks
