# Windows provisioning orchestrator
# Includes all Windows state modules

include:
  # - windows.users  # TODO: Test PowerShell group management approach
  - windows.install
  - windows.config   # Includes service management (merged from services.sls)
  - windows.nvm
  - windows.rust
  - windows.miniforge
  - windows.tasks
