# Windows provisioning orchestrator
# Includes all Windows state modules

include:
  - windows.users
  - windows.install
  - windows.config   # Includes service management (merged from services.sls)
  - windows.nvm
  - windows.rust
  - windows.miniforge
  - windows.windhawk
  - windows.tasks
  #- windows.wt
