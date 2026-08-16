# Windows scheduled tasks
# Deploy tasks defined in pillar via schtasks XML import
# See docs/modules/windows-tasks.md for configuration

enable_schtask_log:
  cmd.run:
    - name: wevtutil set-log Microsoft-Windows-TaskScheduler/Operational /enabled:true /maxSize:104857600
    - shell: powershell

{%- set scheduled_tasks = salt['pillar.get']('scheduled_tasks', {}) %}

{%- for category, tasks_list in scheduled_tasks.items() %}
{%- for task in tasks_list %}
  {%- if task.get('enabled', True) %}

    {%- set task_name = task.get('name', '') %}
    {%- set task_file = task.get('file', '') %}
    {%- set task_display_name = task_name | replace('_', ' ') | title %}

{{ task_name }}_xml:
  file.managed:
    - name: c:/opt/cozy/tasks/{{ category }}/{{ task_name }}.xml
    - source: salt://{{ task_file }}
    - makedirs: True

{{ task_name }}_task:
  cmd.run:
    - name: schtasks /create /tn "\Cozy\{{ category }}\{{ task_display_name }}" /xml "c:/opt/cozy/tasks/{{ category }}\{{ task_name }}.xml" /f
    - onchanges:
      - file: {{ task_name }}_xml

    {%- endif %}
  {%- endfor %}
{%- endfor %}
