# Linux provisioning orchestrator
# Includes all Linux state modules
# Order matters: users must be created before tools that require non-root execution

include:
  - linux.users           # Create admin user and cozyusers group first
  - linux.install
  - linux.workstation_roles  # Workstation role-based packages + GPU detection
  - linux.wsl-config      # WSL-specific config (must run before linux.config)
  - linux.config          # Includes service management (merged from services.sls)
  - linux.docker-proxy    # Deploy Docker socket proxy for TCP access
  - linux.nvm
  - linux.rust
  - linux.miniforge
  - linux.homebrew
