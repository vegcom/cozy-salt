#!jinja|yaml
# Windows Pillar Data
# Configuration values for Windows minions

# User configuration
# Auto-detected from current user (falls back to Administrator if not detected)
{% set detected_user = salt['environ.get']('USERNAME') or 'Administrator' %}
user:
  name: {{ detected_user }}

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
    # FIXME: needs to respect state ( enabeld / disabled )
    #- kubernetes

# Package management preferences (P2 - Role-based selection)
packages:
  manager: chocolatey  # Primary: chocolatey, secondary: winget
  auto_update: False

# Host role (currently unused - all packages from provisioning/packages.sls are installed)
# TODO: Implement role-based filtering to selectively install package categories
host_role: desktop

# Node.js version management via nvm
nvm:
  default_version: 'lts'

# Miniforge package management
miniforge:
  enabled: True
