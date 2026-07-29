# Windows provisioning orchestrator
# Includes all Windows state modules

include:
  - windows.bootstrap
  - windows.scripts
  - windows.salt_minion
  - windows.service-account
  - windows.users
  - windows.smb
  - windows.group
  - windows.paths
  - windows.config
  - windows.install
  - windows.profiles
  - windows.tasks
  - windows.sshd
  - windows.nvm
  - windows.rust
  - windows.miniforge
  - windows.windhawk
  - windows.wsl-integration
  - windows.wt
  - windows.vibeshine
  - windows.tailscale
  - windows.ipfs
