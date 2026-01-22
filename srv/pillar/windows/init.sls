#!jinja|yaml
# Windows Pillar Data
# Configuration values for Windows minions

# User configuration
# Auto-detected from current user (falls back to Administrator if not detected)
{% set detected_user = salt['environ.get']('USERNAME') or 'Administrator' %}
user:
  name: {{ detected_user }}

# Node.js version management via nvm
nvm:
  default_version: 'lts'

# Windows system paths
paths:
  powershell_7_profile: 'C:\Program Files\PowerShell\7'
  sshd_config_d: 'C:\ProgramData\ssh\sshd_config.d'
