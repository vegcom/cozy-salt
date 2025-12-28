# Windows provisioning state
# Applies to all Windows systems (physical and WSL-aware)

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

# Bootstrap script deployment
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

# Scheduled Tasks from XML files
{% load_yaml as tasks %}
wsl:
  - tasks/wsl/WSL autostart.xml
kubernetes:
  - tasks/kubernetes/docker-registry-port-forward.xml
  - tasks/kubernetes/ollama-port-forward.xml
  - tasks/kubernetes/open-webui-port-forward.xml
{% endload %}

{% for category, xmls in tasks.items() %}
{% for xml in xmls %}
{% set task_name = xml.split('/')[-1] | replace('.xml', '') %}
{{ task_name | replace(' ', '_') | replace('-', '_') }}_task:
  win_task.present:
    - name: {{ task_name | replace('-', ' ') | title }}
    - xml_path: salt://windows/{{ xml }}
    - force: True
{% endfor %}
{% endfor %}

# Ensure Salt Minion service is running
salt_minion_service:
  service.running:
    - name: salt-minion
    - enable: True
