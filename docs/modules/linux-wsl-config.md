# WSL Configuration

Windows Subsystem for Linux (WSL) specific configuration via `/etc/wsl.conf`.

## Location

- **State**: `srv/salt/linux/wsl-config.sls`
- **Include**: `linux.init`

## Configures

| Setting | Purpose |
|---------|---------|
| systemd | Enable systemd init system (WSL 2 only) |
| DNS | Control resolver: use Windows host or auto |
| Interop | Windows exe path access from Linux |
| Network | Host IP binding, DHCP relay |

## Configuration File

Manages `/etc/wsl.conf`:
```ini
[boot]
systemd=true

[interop]
appendWindowsPath=true

[network]
generateResolvConf=false
```

## Pillar Configuration

```yaml
wsl:
  systemd_enabled: true
  dns_from_windows: true
  append_windows_path: true
```

## Usage Detection

Auto-detects WSL via:
- `/proc/version` check for "Microsoft" or "WSL"
- Only applies config if running in WSL environment

## Notes

- Only applies on WSL systems (no-op on native Linux)
- Requires WSL 2 for systemd support (WSL 1 won't enable it)
- Needs WSL restart to apply changes
- DNS setting affects container/Kubernetes DNS resolution
