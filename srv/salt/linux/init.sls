# Linux provisioning orchestrator
# Includes all Linux state modules
# Order: groups → install → users (clean dep chain)
#   groups:  no pkg deps, required by install (cozyusers) and users (group.present)
#   install: requires cozyusers group, provides shell_packages
#   users:   requires groups + shell_packages

include:
  - linux.salt_minion     # Configures salt minion.d/99-cozy.conf
  - linux.service-account # Create service account for system operations
  - linux.install         # Role-aware package installation + Docker + GPU detection
  - linux.config-locales  # Deploy system locales (all Linux distros)
  - linux.config-login-manager  # SDDM login manager, autologin, display hooks
  - linux.config-bluetooth    # Bluetooth service and configuration
  - linux.wsl-config      # WSL-specific config (must run before linux.config)
  - linux.config          # Includes service management (merged from services.sls)
  - linux.udev
  - linux.journald
  - linux.pam
  - linux.resolve
  - linux.sshd
  - linux.k3s
  - linux.macvlan-shim    # Macvlan shim for host→container routing (noop if pillar unset)
  - linux.users           # Create users (requires groups + shell_packages)
  - linux.smb             # SMB/CIFS automounts per user
  - linux.nvm
  - linux.rust
  - linux.miniforge
  - linux.homebrew
  - linux.tailscale
  - linux.cozy-presence
  - linux.avahi_service
  - linux.distcc
  - linux.ipfs
