# Linux System Configuration

System-level configuration: tmux, SSH hardening, shell profiles, hosts file, DNS setup.

## Location

- **State**: `srv/salt/linux/config.sls`
- **Include**: `linux.init`

## Manages

| Item              | Purpose                                                        |
| ----------------- | -------------------------------------------------------------- |
| tmux.conf         | System-wide tmux configuration                                 |
| SSH hardening     | Hardened sshd_config deployed from `provisioning/linux/files/` |
| Profile.d scripts | Shell initialization scripts (NVM, Rust, Homebrew paths, etc.) |
| Hosts file        | Service entries (localhost, minion-specific)                   |
| DNS resolution    | Systemd-resolved configuration, nameserver setup               |
| SSH user keys     | SSH config directory and key permissions                       |

## Deployed Files

All from `provisioning/linux/files/etc-skel/`:

- `.config/systemd/user/` - User systemd units
- `.ssh/config` - SSH client configuration
- `.tmux.conf` - Tmux keybindings and settings
- `/etc/profile.d/` - Shell initialization

## Notes

- Merged from `services.sls` (now part of config.sls)
- Requires user creation (`linux.users`) to run first
- SSH hardening follows best practices for security
- DNS setup enables systemd-resolved with fallback nameservers
