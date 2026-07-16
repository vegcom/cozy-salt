#!jinja|yaml
# Salt Scheduler Pillar Configuration
{%- set _common = salt['slsutil.renderer']('/srv/pillar/common/users.sls', default_renderer='jinja|yaml') %}
{%- set is_ci = _common.get('SALT_CI', False) %}

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
