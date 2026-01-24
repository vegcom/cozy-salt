# Windows configuration
# User setup, environment, and system configuration
# See docs/modules/windows-config.md for configuration

{% set network_config = salt['pillar.get']('network', {}) %}
{% set hosts = network_config.get('hosts', {}) %}
{% set paths = salt['pillar.get']('paths', {}) %}
{% set sshd_config_d = paths.get('sshd_config_d', 'C:\\ProgramData\\ssh\\sshd_config.d') %}
{% set pwsh_7_profile = paths.get('powershell_7_profile', 'C:\\Program Files\\PowerShell\\7') %}
{% set pwsh_exe = pwsh_7_profile + "\\pwsh.exe" %}
{% set opt_cozy = "C:\\opt\\cozy\\" %}

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
  reg.write_value:
    - hive: HKLM
    - key: SOFTWARE\OpenSSH
    - vname: DefaultShell
    - vdata: {{ pwsh_exe }}
    - vtype: REG_SZ

# Manage Windows hosts file entries for network services (from pillar.network.hosts)
windows_hosts_entries:
  cmd.run:
    - name: |
        $hostsFile = "C:\Windows\System32\drivers\etc\hosts"
        $entries = @(
        {% for hostname, ip in hosts.items() %}
          "{{ ip }} {{ hostname }}",
        {% endfor %}
        )
        foreach ($entry in $entries) {
          $exists = Select-String -Path $hostsFile -Pattern ([regex]::Escape($entry)) -Quiet -ErrorAction SilentlyContinue
          if (-not $exists) {
            Add-Content -Path $hostsFile -Value $entry
          }
        }
    - shell: pwsh

# Bootstrap script deployment
opt-cozy:
  file.recurse:
    - name: {{ opt_cozy }}
    - source: salt://windows/files/opt-cozy
    - makedirs: True
    - win_owner: Administrators
    - win_inheritance: True

# ============================================================================
# Service Management (merged from services.sls)
# ============================================================================

# Ensure Salt Minion service is running
salt_minion_service:
  service.running:
    - name: salt-minion
    - enable: True
