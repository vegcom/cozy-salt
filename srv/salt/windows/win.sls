# Win physical/WSL setup
detect_wsl:
  cmd.run:
    - name: powershell -c "if (Get-Command wsl -ErrorAction SilentlyContinue) { 'true' } else { 'false' }"
  grains.setval:
    - name: is_wsl
    - value: {{ salt['cmd.run'](...) }}  # From above

# PS1 bootstrap (idempotent)
provision_script:
  file.managed:
    - name: C:\opt\cozy\win.ps1
    - source: salt://files/windows/files/opt-cozy/win.ps1
    - makedirs: True
  cmd.run:
    - name: powershell -ExecutionPolicy Bypass -File C:\opt\cozy\win.ps1
    - creates: C:\opt\cozy\.done.flag

# Tasks (all XMLs)
{% load_yaml as tasks %}
wsl:
  - tasks/wsl/WSL autostart.xml
kubernetes:
  - tasks/kubernetes/docker-registry-port-forward.xml
  - tasks/kubernetes/ollama-port-forward.xml
  - tasks/kubernetes/open-webui-port-forward.xml
{% endload %}
{% for cat, xmls in tasks.items() %}
{% for xml in xmls %}
{{ xml.split('/')[-1]|replace('.xml','') }}_task:
  win_task.present:
    - name: {{ xml.split('/')[-1]|replace('.xml','')|replace('-',' ') | title }}
    - xml: salt://files/windows/{{ xml }}
    - force: True
{% endfor %}
{% endfor %}

salt_minion_tuned:
  service.running:
    - name: salt-minion
    - enable: True