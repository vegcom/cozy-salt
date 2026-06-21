#!jinja|yaml
# Windows scheduled tasks
# Deploy tasks defined in pillar via schtasks XML import
# See docs/modules/windows-tasks.md for configuration

{%- set scheduled_tasks = salt['pillar.get']('scheduled_tasks', {}) %}

{%- for category, tasks_list in scheduled_tasks.items() %}
{%- for task in tasks_list %}
  {%- if task.get('enabled', True) %}

    {%- set task_name = task.get('name', '') %}
    {%- set task_file = task.get('file', '') %}
    {%- set task_display_name = task_name | replace('_', ' ') | title %}

{{ task_name }}_xml:
  file.managed:
    {#- (Get-ScheduledTask -TaskPath '\Cozy\backup\' -TaskName 'Syncthing').State #}
    - name: C:\Windows\Temp\{{ category }}\{{ task_name }}.xml
    - source: salt://{{ task_file }}
    - makedirs: True

{{ task_name }}_task:
  cmd.run:
    - name: schtasks /create /tn "\Cozy\{{ category }}\{{ task_display_name }}" /xml "C:\Windows\Temp\{{ category }}\{{ task_name }}.xml" /f

{{ task_name }}_run:
  cmd.run:
    - name: schtasks /run /tn "\Cozy\{{ category }}\{{ task_display_name }}"
    - unless:
      - schtasks /query /hresult /fo "LIST" /tn "\Cozy\{{ category }}\{{ task_display_name }}"

    {%- endif %}
  {%- endfor %}
{%- endfor %}
