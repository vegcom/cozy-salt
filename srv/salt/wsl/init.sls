# WSL-specific configuration
# Detects WSL availability and configures Docker context for WSL-to-Windows communication
# Only applied when running on Windows with WSL available

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

# Run Docker WSL context configuration script
run_configure_docker_wsl_context:
  cmd.run:
    - name: powershell -ExecutionPolicy Bypass -File C:\opt\cozy\configure-docker-wsl-context.ps1
    - creates: C:\opt\cozy\.done.flag
    - require:
      - file: deploy_configure_docker_wsl_context
