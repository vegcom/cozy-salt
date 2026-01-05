# Windows scheduled tasks
# Import tasks from XML files using schtasks

{% load_yaml as tasks %}
wsl:
  - tasks/wsl/wsl_autostart.xml
kubernetes:
  # FIXME: respect state ( disabled / enabled )
  # TODO: use pillar
  #- tasks/kubernetes/docker_registry_port_forward.xml
  #- tasks/kubernetes/ollama_port_forward.xml
  #- tasks/kubernetes/open_webui_port_forward.xml
{% endload %}

{% for category, xmls in tasks.items() %}
{% for xml in xmls %}
{% set task_name = xml.split('/')[-1] | replace('.xml', '') %}
{% set task_display_name = task_name | replace('_', ' ') | title %}
# Deploy task XML file
{{ task_name }}_xml:
  file.managed:
    - name: C:\Windows\Temp\{{ task_name }}.xml
    - source: salt://windows/{{ xml }}
    - makedirs: True

# Import task using schtasks (only when XML changes)
{{ task_name }}_task:
  cmd.run:
    - name: schtasks /create /tn "\Cozy\{{ task_display_name }}" /xml "C:\Windows\Temp\{{ task_name }}.xml"
    - onchanges:
      - file: {{ task_name }}_xml
{% endfor %}
{% endfor %}
