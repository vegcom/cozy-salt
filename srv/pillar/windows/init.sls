#!jinja|yaml
# Windows Pillar Data
# Configuration values for Windows minions

# User configuration
# Auto-detected from current user (falls back to Administrator if not detected)
{%- set detected_user = salt['environ.get']('USERNAME') or 'Administrator' %}
user:
  name: {{ detected_user }}

# Node.js version management via nvm
nvm:
  default_version: 'lts'

# Pin bootstrap versions here if needed (execution modules not available in pillar):
# _pinned_winget: '1.28.100'
# _pinned_pwsh: '7.5.4'

# Windows system paths
paths:
  powershell_7_profile: 'C:\Program Files\PowerShell\7'
  sshd_config_d: 'C:\ProgramData\ssh\sshd_config.d'

# Windows scheduled tasks (define tasks to deploy via schtasks)
# Each task references an XML file in provisioning/windows/tasks/
# Though salt file roots are even, so it's windows/tasks/
# Set enabled: False to skip deployment of specific tasks
scheduled_tasks:
  wsl:
    - name: wsl_autostart
      file: windows/tasks/wsl/wsl_autostart.xml
      enabled: True
  backup:
    - name: restore_point
      file: windows/tasks/backup/restore_point.xml
      enabled: True
    - name: syncthing
      file: windows/tasks/backup/syncthing.xml
      enabled: True
  net:
    - name: tor
      file: windows/tasks/net/tor.xml
      enabled: True
    - name: shadowsocks
      file: windows/tasks/net/shadowsocks.xml
      enabled: True
    - name: tailscale
      file: windows/tasks/net/tailscale.xml
      enabled: True
    - name: ipfs
      file: windows/tasks/net/ipfs.xml
      enabled: True
  kubernetes:
    - name: docker_registry_port_forward
      file: windows/tasks/kubernetes/docker_registry_port_forward.xml
      enabled: False
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
