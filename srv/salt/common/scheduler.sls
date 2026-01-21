#!jinja|yaml
# Salt Scheduler State Configuration
# Applies scheduled jobs from pillar data to minions
#
# Pillar structure (define in srv/pillar/*/scheduler.sls):
#   schedule:
#     job_name:
#       function: module.function
#       seconds: 3600
#       args: [arg1, arg2]

# Import scheduler configuration from pillar
{% set schedules = salt['pillar.get']('schedule', {}) %}

# Apply each scheduled job to the minion
{% for job_name, job_config in schedules.items() %}
schedule_{{ job_name }}:
  schedule.present:
    - name: {{ job_name }}
    - function: {{ job_config.get('function') }}
    {% if 'seconds' in job_config %}
    - seconds: {{ job_config['seconds'] }}
    {% endif %}
    {% if 'minutes' in job_config %}
    - minutes: {{ job_config['minutes'] }}
    {% endif %}
    {% if 'hours' in job_config %}
    - hours: {{ job_config['hours'] }}
    {% endif %}
    {% if 'days' in job_config %}
    - days: {{ job_config['days'] }}
    {% endif %}
    {% if 'cron' in job_config %}
    - cron: {{ job_config['cron'] }}
    {% endif %}
    {% if 'when' in job_config %}
    - when: {{ job_config['when'] }}
    {% endif %}
    {% if 'start' in job_config %}
    - start: {{ job_config['start'] }}
    {% endif %}
    {% if 'end' in job_config %}
    - end: {{ job_config['end'] }}
    {% endif %}
    {% if 'args' in job_config %}
    - args: {{ job_config['args'] | tojson }}
    {% endif %}
    {% if 'kwargs' in job_config %}
    - kwargs: {{ job_config['kwargs'] | tojson }}
    {% endif %}
    {% if 'splay' in job_config %}
    - splay:
      {% if 'start' in job_config['splay'] %}
      - start: {{ job_config['splay']['start'] }}
      {% endif %}
      {% if 'end' in job_config['splay'] %}
      - end: {{ job_config['splay']['end'] }}
      {% endif %}
    {% endif %}
    {% if 'enabled' in job_config %}
    - enabled: {{ job_config['enabled'] | lower }}
    {% endif %}
    {% if 'return_job' in job_config %}
    - return_job: {{ job_config['return_job'] | lower }}
    {% endif %}
{% endfor %}
