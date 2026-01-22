# Homebrew - Linux

Homebrew package manager installation for Linux with ACL-based group permissions.

## Location

- **State**: `srv/salt/linux/homebrew.sls`
- **Include**: `linux.init`

## Installation

Installs Homebrew from official site: <https://brew.sh>

| Item        | Location                               |
| ----------- | -------------------------------------- |
| Homebrew    | `/opt/homebrew`                        |
| Shell init  | `/etc/profile.d/homebrew-init.sh`      |
| Permissions | Admin user in homebrew group can write |

## Purpose

Cross-platform package manager for:

- Consistent packages across macOS/Linux
- Tools not in distro repos
- Custom/bleeding-edge versions

## Usage

```bash
brew install formula     # Install package
brew upgrade            # Update all
brew list              # List installed
brew search keyword    # Search
```

## Notes

- Requires curl (installed via core_utils)
- Group-based ACL permissions (admin user joins homebrew group)
- Shell profile auto-sources Homebrew on login
- Slower than distro package managers; use native packages first
- Cross-platform consistency: same packages work on macOS and Linux
