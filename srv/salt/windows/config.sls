# Windows configuration
# User setup, environment, and system configuration

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
provision_script:
  file.managed:
    - name: C:\opt\cozy\win.ps1
    - source: salt://windows/files/opt-cozy/win.ps1
    - makedirs: True

run_provision_script:
  cmd.run:
    - name: powershell -ExecutionPolicy Bypass -File C:\opt\cozy\win.ps1
    - creates: C:\opt\cozy\.done.flag
    - require:
      - file: provision_script

# Deploy hardened SSH configuration
sshd_hardening_config:
  file.managed:
    - name: C:\ProgramData\ssh\sshd_config.d\99-hardening.conf
    - source: salt://windows/files/ProgramData/ssh/sshd_config.d/99-hardening.conf
    - makedirs: True
