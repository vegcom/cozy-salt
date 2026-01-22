# Custom Pacman Execution Module

Custom Salt execution module for Arch Linux pacman package manager with clean environment.

## Location

- **Code**: `srv/salt/_modules/pacman.py`
- **Type**: Execution module (extends salt.modules)

## Purpose

Provides pacman-specific functionality:

- Clean environment execution (removes user config)
- Batch package operations
- Architecture-specific handling (x86_64, aarch64)
- Update operations

## Functions Provided

| Function           | Purpose                         |
| ------------------ | ------------------------------- |
| `pacman.installed` | Install packages (batch)        |
| `pacman.removed`   | Remove packages (batch)         |
| `pacman.sync`      | Sync database before operations |
| `pacman.clean`     | Clean package cache             |

## Usage in States

```sls
install_packages:
  pacman.installed:
    - pkgs:
      - vim
      - git
      - base-devel
    - refresh: True
```

## Environment Handling

Runs with clean environment:

- Removes `MAKEFLAGS` (build customization)
- Removes `PACMAN_OPTS` (user configuration)
- Isolates from user ~/.config/pacman/
- Ensures reproducible builds

## Notes

- Arch Linux only
- Executes as root (typical for package management)
- Handles both official repos and AUR (via yay)
- Safe package name deduplication
