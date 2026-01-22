# Pillar: Linux Configuration

Linux-specific default pillar configuration.

## Location

- **Pillar**: `srv/pillar/linux/init.sls`
- **Included in**: `top.sls` for all Linux systems

## Configures

```yaml
user:
  name: ubuntu              # Default admin user

workstation_role: workstation-base  # Package capability set

nvm:
  default_version: 'lts/*'

host:
  capabilities:
    kvm: false             # KVM disabled by default
  services:
    ssh_enabled: true      # SSH service control
```

## User Detection

Auto-detects admin user:

```yaml
user:
  name: {{ detected_user }}
```

Detection order:
1. Container detection: defaults to `root`
2. SUDO_USER environment variable
3. LOGNAME environment variable
4. Falls back to: `root`

## Workstation Roles

Defines package installation scope:

| Role | Includes |
|------|----------|
| workstation-minimal | core_utils, shell_enhancements |
| workstation-base | minimal + monitoring, vcs, cli, security, acl |
| workstation-developer | base + build_tools, networking, kvm |
| workstation-full | developer + interpreters, fonts, theming (Arch only) |

## Capabilities

Fine-grained control:

```yaml
host:
  capabilities:
    kvm: true              # Enable KVM/libvirt
```

Gated by `pillar_gate` in capability_meta.

## Services

Service management:

```yaml
host:
  services:
    ssh_enabled: true      # Enable SSH service
```

## Customization

Override per-host in `srv/pillar/host/{hostname}.sls`:

```yaml
workstation_role: workstation-developer  # More packages
nvm:
  default_version: v18.0.0  # Specific Node version
```

## Notes

- Applied to all Linux systems (Debian, RHEL, Arch)
- Role determines installed capabilities
- KVM gated by capability flag
- User auto-detected in containers
- Per-host overrides in host-specific pillar
