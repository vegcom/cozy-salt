# Windows provisioning orchestrator
# Includes all Windows state modules

include:
  - windows.users
  - windows.install
  - windows.config
  - windows.nvm
  - windows.rust
  - windows.miniforge
  - windows.tasks
  - windows.services
