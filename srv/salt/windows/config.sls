# Windows configuration
# User setup, environment, and system configuration

{% set network_config = salt['pillar.get']('network', {}) %}
{% set hosts = network_config.get('hosts', {}) %}

# Detect if WSL is available and set grain for future targeting
detect_wsl:
  cmd.run:
    - name: powershell -NoProfile -Command "if (Get-Command wsl -ErrorAction SilentlyContinue) { 'true' } else { 'false' }"
    - stateful: False
  grains.present:
    - name: is_wsl
    - value: True
    - require:
      - cmd: detect_wsl

# Bootstrap script deployment (Docker context setup)
deploy_configure_docker_wsl_context:
  file.managed:
    - name: C:\opt\cozy\configure-docker-wsl-context.ps1
    - source: salt://windows/files/opt-cozy/configure-docker-wsl-context.ps1
    - makedirs: True

run_configure_docker_wsl_context:
  cmd.run:
    - name: powershell -ExecutionPolicy Bypass -File C:\opt\cozy\configure-docker-wsl-context.ps1
    - creates: C:\opt\cozy\.done.flag
    - require:
      - file: deploy_configure_docker_wsl_context

# Deploy hardened SSH configuration (consolidated template - High-003)
# Template handles platform conditionals: Linux, WSL, and Windows
sshd_hardening_config:
  file.managed:
    - name: C:\ProgramData\ssh\sshd_config.d\99-hardening.conf
    - source: salt://_templates/sshd_hardening.conf.jinja
    - template: jinja
    - makedirs: True

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
    - shell: powershell

# Export git user config as environment variables for vim
# Implementation delegated to common.git_env module (platform-specific)
include:
  - common.git_env

# ============================================================================
# Service Management (merged from services.sls)
# ============================================================================

# Ensure Salt Minion service is running
salt_minion_service:
  service.running:
    - name: salt-minion
    - enable: True
