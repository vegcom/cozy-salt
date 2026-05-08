{% set paths = salt['pillar.get']('paths', {}) %}
{% set sshd_config_d = paths.get('sshd_config_d', 'C:\\ProgramData\\ssh\\sshd_config.d') %}
{% set sshd_config = paths.get('sshd_config', 'C:\\ProgramData\\ssh\\sshd_config') %}
{% set pwsh_7_profile = paths.get('powershell_7_profile', 'C:\\Program Files\\PowerShell\\7') %}
{% set pwsh_exe = pwsh_7_profile + "\\pwsh.exe" %}

# Deploy base sshd_config (enables drop-in dir + authorized keys paths)
sshd_base_config:
  file.managed:
    - name: {{ sshd_config }}
    - source: salt://windows/files/ProgramData-ssh/sshd_config
    - makedirs: True

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

sshd_service:
  service.running:
    - name: sshd
    - enable: True
    - watch:
      - file: sshd_base_config
      - file: sshd_hardening_config
