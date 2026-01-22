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

# Windows scheduled tasks (define tasks to deploy via schtasks)
# Each task references an XML file in provisioning/windows/tasks/
# Set enabled: False to skip deployment of specific tasks
scheduled_tasks:
  wsl:
    - name: wsl_autostart
      file: provisioning/windows/tasks/wsl/wsl_autostart.xml
      enabled: True
  kubernetes:
    - name: docker_registry_port_forward
      file: provisioning/windows/tasks/kubernetes/docker_registry_port_forward.xml
      enabled: False  # Disabled by default; enable in host/class pillar if needed
    - name: ollama_port_forward
      file: provisioning/windows/tasks/kubernetes/ollama_port_forward.xml
      enabled: False
    - name: open_webui_port_forward
      file: provisioning/windows/tasks/kubernetes/open_webui_port_forward.xml
      enabled: False
