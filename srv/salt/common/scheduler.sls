#!jinja|yaml
# Salt Scheduler State Configuration
# NOTE: Schedules now managed on MASTER (srv/master.d/schedule.conf)
# This state absents any legacy minion-side schedules

# Absent legacy minion schedules (highstates moved to master orchestration)
# Note: windows_health_check stays minion-side (needs local DISM access)
{% set legacy_schedules = ['linux_highstate', 'daily_highstate'] %}
{% for job_name in legacy_schedules %}
absent_legacy_schedule_{{ job_name }}:
  schedule.absent:
    - name: {{ job_name }}
{% endfor %}

# Keep ability to deploy minion-specific schedules if needed (rare)
{% set schedules = salt['pillar.get']('schedule', {}) %}
{% for job_name, job_config in schedules.items() %}
schedule_{{ job_name }}:
  schedule.present:
    - name: {{ job_name }}
    - function: {{ job_config.get('function') }}
    {% if 'seconds' in job_config %}- seconds: {{ job_config['seconds'] }}{% endif %}
    {% if 'minutes' in job_config %}- minutes: {{ job_config['minutes'] }}{% endif %}
    {% if 'hours' in job_config %}- hours: {{ job_config['hours'] }}{% endif %}
    {% if 'days' in job_config %}- days: {{ job_config['days'] }}{% endif %}
    {% if 'cron' in job_config %}- cron: {{ job_config['cron'] }}{% endif %}
    {% if 'when' in job_config %}- when: {{ job_config['when'] }}{% endif %}
    {% if 'args' in job_config %}- args: {{ job_config['args'] | tojson }}{% endif %}
    {% if 'kwargs' in job_config %}- kwargs: {{ job_config['kwargs'] | tojson }}{% endif %}
    {% if 'enabled' in job_config %}- enabled: {{ job_config['enabled'] | lower }}{% endif %}
{% endfor %}
