# Windows scheduled tasks
# Deploy tasks defined in pillar via schtasks XML import
# See docs/modules/windows-tasks.md for configuration

{% set scheduled_tasks = salt['pillar.get']('scheduled_tasks', {}) %}

{% for category, tasks_list in scheduled_tasks.items() %}
{% for task in tasks_list %}
{% if task.get('enabled', True) %}
{% set task_name = task.get('name', '') %}
{% set task_file = task.get('file', '') %}
{% set task_display_name = task_name | replace('_', ' ') | title %}

# Deploy task XML file for {{ category }}/{{ task_name }}
{{ task_name }}_xml:
  file.managed:
    - name: C:\Windows\Temp\{{ task_name }}.xml
    - source: salt://{{ task_file }}
    - makedirs: True

# Import task using schtasks (only when XML changes)
{{ task_name }}_task:
  cmd.run:
    - name: schtasks /create /tn "\Cozy\{{ task_display_name }}" /xml "C:\Windows\Temp\{{ task_name }}.xml" /f
    - onchanges:
      - file: {{ task_name }}_xml
{% endif %}
{% endfor %}
{% endfor %}
