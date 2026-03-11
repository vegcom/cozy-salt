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
{% set _winget_ver = salt['pillar.get']('_pinned_winget', salt['github_release.latest']('microsoft/winget-cli', fallback='1.28.100')) %}
{% set _pwsh_ver = salt['pillar.get']('_pinned_pwsh', salt['github_release.latest']('PowerShell/PowerShell', fallback='7.5.4')) %}
bootstrap:
  url:
    winget: 'https://github.com/microsoft/winget-cli/releases/download/v{{ _winget_ver }}/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle'
    pwsh: 'https://github.com/PowerShell/PowerShell/releases/download/v{{ _pwsh_ver }}/PowerShell-{{ _pwsh_ver }}.msixbundle'

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

choco_features:
  - allowGlobalConfirmation
  - allowEmptyChecksumsSecure
  - useEnhancedExitCodes
  - failOnStandardError
  - failOnAutoUninstaller
  - removePackageInformationOnUninstall

# Salt scheduler - Windows health check (stays minion-side)
# Highstates moved to master (srv/master.d/schedule.conf)
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
