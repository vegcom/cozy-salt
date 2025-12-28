# Windows scheduled tasks
# Import tasks from XML files using schtasks

{% load_yaml as tasks %}
wsl:
  - tasks/wsl/wsl-autostart.xml
kubernetes:
  - tasks/kubernetes/docker-registry-port-forward.xml
  - tasks/kubernetes/ollama-port-forward.xml
  - tasks/kubernetes/open-webui-port-forward.xml
{% endload %}

{% for category, xmls in tasks.items() %}
{% for xml in xmls %}
{% set task_name = xml.split('/')[-1] | replace('.xml', '') %}
{% set task_display_name = task_name | replace('-', ' ') | title %}
# Deploy task XML file
{{ task_name | replace(' ', '_') | replace('-', '_') }}_xml:
  file.managed:
    - name: C:\Windows\Temp\{{ task_name }}.xml
    - source: salt://windows/{{ xml }}
    - makedirs: True

# Import task using schtasks
{{ task_name | replace(' ', '_') | replace('-', '_') }}_task:
  cmd.run:
    - name: schtasks /create /tn "\Cozy\{{ task_display_name }}" /xml "C:\Windows\Temp\{{ task_name }}.xml" /f
    - require:
      - file: {{ task_name | replace(' ', '_') | replace('-', '_') }}_xml
{% endfor %}
{% endfor %}
