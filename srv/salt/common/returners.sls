# Configures salt-minion returner (cozy_notify desktop toasts)
# Master-side job cache handled via master_job_cache: mongo in master conf

{%- set is_windows = grains['os'] == 'Windows' %}

include:
{%- if not is_windows %}
  - linux.returners
{%- else %}
  - windows.returners
{%- endif %}
