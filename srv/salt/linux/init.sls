# Linux provisioning orchestrator
# Includes all Linux state modules
# Order matters: users must be created before tools that require non-root execution

include:
  - linux.users           # Create admin user and cozyusers group first
  - linux.service-account # Create service account for system operations
  - linux.install         # Role-aware package installation + Docker + GPU detection
  - linux.config-locales  # Deploy system locales (all Linux distros)
  - linux.dist.config-pacman  # Arch: Manage pacman.conf and repos
  - linux.config-login-manager  # SDDM login manager, autologin, display hooks
  - linux.config-bluetooth    # Bluetooth service and configuration
  - linux.wsl-config      # WSL-specific config (must run before linux.config)
  - linux.config          # Includes service management (merged from services.sls)
  - linux.docker-proxy    # Deploy Docker socket proxy for TCP access
  - linux.nvm
  - linux.rust
  - linux.miniforge
  - linux.homebrew
  - linux.cozy-presence
