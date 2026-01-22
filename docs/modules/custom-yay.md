# Custom Yay Execution Module

Custom Salt execution module for Arch User Repository (AUR) helper yay with non-root execution.

## Location

- **Code**: `srv/salt/_modules/yay.py`
- **Type**: Execution module (extends salt.modules)

## Purpose

Provides yay-specific functionality:
- AUR package installation
- Non-root execution (security)
- Clean environment handling
- Batch operations

## Functions Provided

| Function | Purpose |
|----------|---------|
| `yay.installed` | Install packages from AUR |
| `yay.removed` | Remove AUR packages |
| `yay.sync` | Sync AUR database |
| `yay.search` | Search AUR |

## Usage in States

```sls
install_aur_packages:
  yay.installed:
    - pkgs:
      - some-aur-package
      - another-aur-app
    - user: builder  # Non-root user
    - refresh: True
```

## Non-Root Execution

Runs as unprivileged user:
- Requires `builder` user setup
- Avoids sudo complications with AUR build
- Uses sudoers for pacman operations
- Safe for automated builds

## Environment Handling

Clean environment:
- Removes `MAKEFLAGS`
- Removes user configuration
- Isolated from home directory
- Reproducible builds

## Sudoers Configuration

Requires entry for `builder` user:
```
builder ALL=(ALL) NOPASSWD: /usr/bin/pacman
builder ALL=(ALL) NOPASSWD: /usr/bin/systemctl
```

## Notes

- Arch Linux only
- Requires yay binary installed first
- AUR build takes longer than binary packages
- Network access required (fetches from AUR)
