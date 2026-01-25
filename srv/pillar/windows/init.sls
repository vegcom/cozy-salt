#!jinja|yaml
# Windows Pillar Data
# Configuration values for Windows minions

# User configuration
# Auto-detected from current user (falls back to Administrator if not detected)
{% set detected_user = salt['environ.get']('USERNAME') or 'Administrator' %}
user:
  name: {{ detected_user }}

# Node.js version management via nvm
nvm:
  default_version: 'lts'

# Windows system paths
paths:
  powershell_7_profile: 'C:\Program Files\PowerShell\7'
  sshd_config_d: 'C:\ProgramData\ssh\sshd_config.d'
  winget: 'C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_1.27.460.0_x64__8wekyb3d8bbwe'

# Bootstrap packages - URLs for AppX/MSIX bundles
bootstrap:
  url:
    winget: 'https://github.com/microsoft/winget-cli/releases/download/v1.28.100-preview/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle'
    pwsh: 'https://github.com/PowerShell/PowerShell/releases/download/v7.5.4/PowerShell-7.5.4.msixbundle'

# Windows scheduled tasks (define tasks to deploy via schtasks)
# Each task references an XML file in provisioning/windows/tasks/
# Though salt file roots are even, so it's windows/tasks/
# Set enabled: False to skip deployment of specific tasks
scheduled_tasks:
  wsl:
    - name: wsl_autostart
      file: windows/tasks/wsl/wsl_autostart.xml
      enabled: True
  kubernetes:
    - name: docker_registry_port_forward
      file: windows/tasks/kubernetes/docker_registry_port_forward.xml
      enabled: False  # Disabled by default; enable in host/class pillar if needed
    - name: ollama_port_forward
      file: windows/tasks/kubernetes/ollama_port_forward.xml
      enabled: False
    - name: open_webui_port_forward
      file: windows/tasks/kubernetes/open_webui_port_forward.xml
      enabled: False

# Salt scheduler - Windows health check
# Runs DISM ScanHealth weekly; bad return triggers reactor -> emergency-maint.ps1
schedule:
  windows_health_check:
    function: cmd.script
    args:
      - salt://windows/files/opt-cozy/health-check.ps1
    kwargs:
      shell: powershell
    days: 7
    enabled: True
    return_job: True
