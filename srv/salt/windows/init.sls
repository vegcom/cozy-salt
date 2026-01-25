# Windows provisioning orchestrator
# Includes all Windows state modules

include:
  # Bootstrap FIRST - WinRM, UAC, C:\opt ACLs
  - windows.bootstrap
  - windows.users
  - windows.service-account
  - windows.paths
  - windows.install
  - windows.config
  - windows.profiles
  - windows.nvm
  - windows.rust
  - windows.miniforge
  - windows.windhawk
  - windows.tasks
  - windows.wsl-integration
