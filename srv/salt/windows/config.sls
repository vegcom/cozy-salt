# Windows configuration
# User setup, environment, and system configuration

{% set network_config = salt['pillar.get']('network', {}) %}
{% set hosts = network_config.get('hosts', {}) %}

# WSL-specific configuration (detection and Docker context setup)
# Export git user config as environment variables for vim
include:
  - wsl
  - common.git_env

# Deploy hardened SSH configuration (consolidated template - High-003)
# Template handles platform conditionals: Linux, WSL, and Windows
sshd_hardening_config:
  file.managed:
    - name: C:\ProgramData\ssh\sshd_config.d\99-hardening.conf
    - source: salt://_templates/sshd_hardening.conf.jinja
    - template: jinja
    - makedirs: True

# Set PowerShell 7 as default shell for OpenSSH connections
# This makes SSH sessions drop into pwsh instead of cmd.exe
# Prefers stable (7) if available, falls back to preview (7-preview)
openssh_default_shell:
  cmd.run:
    - name: powershell -NoProfile -Command "$path = if (Test-Path 'C:\Program Files\PowerShell\7\pwsh.exe') { 'C:\Program Files\PowerShell\7\pwsh.exe' } else { 'C:\Program Files\PowerShell\7-preview\pwsh.exe' }; New-ItemProperty -Path 'HKLM:\SOFTWARE\OpenSSH' -Name DefaultShell -Value $path -PropertyType String -Force | Out-Null"
    - shell: cmd

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

# ============================================================================
# Service Management (merged from services.sls)
# ============================================================================

# Ensure Salt Minion service is running
salt_minion_service:
  service.running:
    - name: salt-minion
    - enable: True
