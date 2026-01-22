# Windows System Configuration

Windows system configuration: SSH hardening, OpenSSH setup, hosts file, WSL integration.

## Location

- **State**: `srv/salt/windows/config.sls`
- **Include**: `windows.init`

## Configures

| Item            | Purpose                                   |
| --------------- | ----------------------------------------- |
| SSH hardening   | Hardened sshd_config deployment           |
| OpenSSH service | Install and configure Windows OpenSSH     |
| Hosts file      | Service entries (localhost, Docker, etc.) |
| WSL integration | Docker Desktop/WSL bridge setup           |
| SSH keys        | SSH directory permissions and setup       |

## SSH Configuration

Deploys hardened `/etc/ssh/sshd_config`:

- Key-based auth only (password disabled)
- Root login disabled
- Port configuration
- Security hardening options

## Hosts File

Manages `C:\Windows\System32\drivers\etc\hosts`:

- localhost mappings
- Docker Desktop entries
- Service host entries

## WSL Integration

Configures Docker context for:

- WSL 2 Docker daemon access
- WSL Windows app integration
- File sharing between systems

## Notes

- Requires OpenSSH feature installed first (windows.install)
- SSH service auto-enabled and started
- Changes require service restart
- WSL detection automatic
