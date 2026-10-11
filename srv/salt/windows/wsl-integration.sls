# WSL-specific configuration
# Detects WSL availability and configures Docker context for WSL-to-Windows communication
# Only applied when running on Windows with WSL available

# Detect if WSL is available and set grain for future targeting
detect_wsl:
  cmd.run:
    - name: if (Get-Command wsl -ErrorAction SilentlyContinue) { 'true' } else { 'false' }
    - stateful: False
    - shell: powershell
  grains.present:
    - name: is_wsl
    - value: True
    - require:
      - cmd: detect_wsl

# Run Docker WSL context configuration script
run_configure_docker_wsl_context:
  cmd.run:
    - name: C:/opt/cozy/bin/configure-docker-wsl-context.ps1
    - shell: powershell
    - success_retcodes:
      - 0
      - 1

# Configure Windows firewall to exclude port range 60000-62000 for WSL Docker TCP access
run_configure_docker_wsl_context:
  cmd.run:
    - names:
      - netsh int ipv4 add excludedportrange protocol=tcp startport=60000 numberofports=2000 store=persistent
      - netsh int ipv6 add excludedportrange protocol=tcp startport=60000 numberofports=2000 store=persistent
    - shell: powershell
    - success_retcodes:
      - 0
      - 1
