# WSL-specific configuration
# Detects WSL availability and configures Docker context for WSL-to-Windows communication
# Only applied when running on Windows with WSL available

# Detect if WSL is available and set grain for future targeting
detect_wsl:
  cmd.run:
    - name: pwsh -Command "if (Get-Command wsl -ErrorAction SilentlyContinue) { 'true' } else { 'false' }"
    - stateful: False
    - shell: pwsh
  grains.present:
    - name: is_wsl
    - value: True
    - require:
      - cmd: detect_wsl

# Run Docker WSL context configuration script
run_configure_docker_wsl_context:
  cmd.run:
    - name: pwsh -ExecutionPolicy Bypass -File C:\opt\cozy\bin\configure-docker-wsl-context.ps1
    - shell: pwsh
    - unless: docker context ls --format "{{ '{{.Name}}' }}" | findstr /C:"wsl"
