# Linux User Management

Create admin user, cozyusers group, and deploy skeleton files (.bashrc, .ssh, etc.) to home directory.

## Location

- **State**: `srv/salt/linux/users.sls`
- **Skeleton files**: `provisioning/linux/files/etc-skel/`
- **Include**: `linux.init` (runs first, before other Linux states)

## Creates

| Item | Details |
|------|---------|
| Admin user | Dynamic: uses `linux:user:name` pillar or auto-detected from container/WSL |
| cozyusers group | Group for non-admin users in shared environments |
| Home directory | /home/{user} with proper permissions |
| Skeleton files | .bashrc, .zshrc, .bash_profile, .profile, SSH keys, .ssh/config |
| User groups | Adds admin user to: sudo, wheel, libvirt, kvm, docker (if applicable) |

## Pillar Configuration

```yaml
user:
  name: ubuntu  # or detected automatically in containers
```

Detected automatically:
- Container: defaults to root
- Bare metal: tries SUDO_USER → LOGNAME → root

## Notes

- Must run before other Linux states (service startup, installations expect user to exist)
- SSH directory created with 700 permissions
- Skeleton files deployed from `provisioning/linux/files/etc-skel/`
- Group membership gates features (docker/kvm services require group membership)
