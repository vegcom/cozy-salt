# Windows Pillar Data
# Configuration values for Windows minions

# Provisioning paths
cozy:
  base_path: 'C:\opt\cozy'
  done_flag: 'C:\opt\cozy\.done.flag'

# Docker configuration (for WSL integration)
docker:
  context_name: wsl
  host: tcp://127.0.0.1:2375

# Scheduled tasks to deploy
tasks:
  enabled: True
  categories:
    - wsl
    - kubernetes

# Package management preferences
packages:
  manager: chocolatey  # Primary: chocolatey, secondary: winget
  auto_update: False
