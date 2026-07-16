#!jinja|yaml
# Salt Scheduler Pillar Configuration
{%- set is_ci = salt['pillar.get']('SALT_CI', False) %}

{%- if not is_ci %}
schedule:

  mongo_returner_sync:
    function: state.sls
    args:
      - common.mongo_returner
    minutes: 60
    enabled: true

  salt_version_sync:
    function: state.sls
    args:
      - common.salt
    hours: 48
    enabled: true
{%- endif %}
