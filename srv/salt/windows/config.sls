# Windows configuration
# User setup, environment, and system configuration
# See docs/modules/windows-config.md for configuration

{% set paths = salt['pillar.get']('paths', {}) %}
{% set sshd_config_d = paths.get('sshd_config_d', 'C:\\ProgramData\\ssh\\sshd_config.d') %}
{% set pwsh_7_profile = paths.get('powershell_7_profile', 'C:\\Program Files\\PowerShell\\7') %}
{% set pwsh_exe = pwsh_7_profile + "\\pwsh.exe" %}


# WSL-specific configuration (detection and Docker context setup)
# Export git user config as environment variables for vim
include:
  - windows.wsl-integration
  - common.git_env

# Deploy hardened SSH configuration (consolidated template - High-003)
# Template handles platform conditionals: Linux, WSL, and Windows
sshd_hardening_config:
  file.managed:
    - name: {{ sshd_config_d }}\99-hardening.conf
    - source: salt://_templates/sshd_hardening.conf.jinja
    - template: jinja
    - makedirs: True

# Set PowerShell 7 as default shell for OpenSSH connections
# This makes SSH sessions drop into pwsh instead of cmd.exe
# Prefers stable (7) if available, falls back to preview (7-preview)
openssh_default_shell:
  reg.present:
    - name: HKLM\SOFTWARE\OpenSSH
    - vname: DefaultShell
    - vdata: {{ pwsh_exe }}
    - vtype: REG_SZ

# Auto-elevate admin accounts without UAC prompt
# Allows salt-minion and cozy-salt-svc to run elevated silently
uac_auto_elevate_admins:
  reg.present:
    - name: HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System
    - vname: ConsentPromptBehaviorAdmin
    - vdata: 0
    - vtype: REG_DWORD

# Hosts entries managed in common.hosts (cross-platform)


# ============================================================================
# Service Management (merged from services.sls)
# ============================================================================

# Ensure Salt Minion service is running
salt_minion_service:
  service.running:
    - name: salt-minion
    - enable: True
