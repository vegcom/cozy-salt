# Linux Package Installation

Distro-aware package installation dispatcher. Routes to Debian, RHEL, or Arch-specific implementations based on grains.

## Location

- **State**: `srv/salt/linux/install.sls`
- **Packages**: `provisioning/packages.sls`
- **Include**: `linux.init`

## Operation

Installs capability-based package groups via pillar configuration:

1. Detects OS family (Debian, RedHat, Arch)
2. Includes distro-specific state: `linux.dist.{debian,rhel,archlinux}`
3. Each distro state installs capabilities from `provisioning/packages.sls`
4. Capabilities gated by pillar `host.capabilities` and role

## Package Capabilities

Installed based on `workstation_role`:

- **workstation-minimal**: core_utils, shell_enhancements
- **workstation-base**: adds monitoring, compression, vcs_extras, modern_cli, security, acl
- **workstation-developer**: adds build_tools, networking, kvm
- **workstation-full**: adds interpreters, fonts, theming, modern_cli_extras (Arch only)

## Configuration

Define in pillar:

```yaml
workstation_role: workstation-base # or minimal/developer/full

host:
  capabilities:
    kvm: true # Enable KVM/libvirt installation
```

## Notes

- Requires `apt_update` before package installation on Debian/Ubuntu
- RHEL excludes duf, ncdu (requires EPEL)
- Arch uses yay for AUR packages, requires bootstrap first
- See `docs/package-management.md` for full capability list
