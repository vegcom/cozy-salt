# Windows configuration
# User setup, environment, and system configuration
# See docs/modules/windows-config.md for configuration

# WSL-specific configuration (detection and Docker context setup)
# Export git user config as environment variables for vim
include:
  - windows.wsl-integration
  - common.git_env

# Auto-elevate admin accounts without UAC prompt
# Allows salt-minion and cozy-salt-svc to run elevated silently
uac_auto_elevate_admins:
  reg.present:
    - name: HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System
    - vname: ConsentPromptBehaviorAdmin
    - vdata: 0
    - vtype: REG_DWORD

# Hosts entries managed in common.hosts (cross-platform)
