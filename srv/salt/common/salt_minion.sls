{%- set salt_master = salt['pillar.get']('salt:master', '') %}

{%- if grains['os_family'] == 'Windows' %}
  {%- set minion_conf_dir = 'C:/salt/conf/' %}
{%- else %}
  {%- set minion_conf_dir = '/etc/salt/' %}
{%- endif %}

{%- set minion_conf = minion_conf_dir ~ '/minion' %}
{%- set minion_conf_beacon = minion_conf_dir ~ '/minion.d/97-beacon.conf' %}
{%- set minion_conf_timeout = minion_conf_dir ~ '/minion.d/98-timeout.conf' %}
{%- set minion_conf_grains = minion_conf_dir ~ '/minion.d/96-grains.conf' %}
{%- set minion_conf_logging = minion_conf_dir ~ '/minion.d/95-logging.conf' %}

{%- set minion_conf_opt = minion_conf_dir ~ '/minion.d/99-cozy.conf' %}

{%- set minion_conf_obj = "default_include: " ~ "minion.d/*.conf" ~ "\n" %}

{%- if grains['os_family'] != 'Windows' %}
  {%- set salt_modules = salt['pillar.get']('salt:modules:linux', ["pyinotify", "gitpython", "pymongo"]) %}
{%- else %}
  {%- set salt_modules = salt['pillar.get']('salt:modules:windows', ["gitpython", "pymongo"]) %}
{%- endif %}

{%- set minion_confd_obj = "" %}
{%- if salt_master %}
{%- set minion_confd_obj = "master: " ~ salt_master ~ "\n" %}
{%- endif %}

salt_minion_conf:
  file.managed:
    - name: {{ minion_conf }}
    - makedirs: True
    - contents: {{ minion_conf_obj | yaml_encode }}
    {%- if grains['os_family'] != 'Windows' %}
    - mode: '0644'
    {%- endif %}

salt_minion_conf_opt:
  file.managed:
    - name: {{ minion_conf_opt }}
    - makedirs: True
    - contents: {{ minion_confd_obj | yaml_encode }}
    {%- if grains['os_family'] != 'Windows' %}
    - mode: '0644'
    {%- endif %}

salt_minion_conf_timeout:
  file.managed:
    - name: {{ minion_conf_timeout }}
    - makedirs: True
     {%- if grains['os_family'] != 'Windows' %}
    - mode: '0644'
    {%- endif %}
    - contents: |
        # Fast-fail timeout profile — tuned for cozy-salt multi-OS cluster
        # See: https://docs.saltproject.io/en/latest/ref/configuration/minion.html

        # Authentication — detect dead master quickly
        auth_timeout: 5
        auth_tries: 3
        master_alive_interval: 30

        # TCP keepalive — critical for Windows minions that silently die
        tcp_keepalive: True
        tcp_keepalive_idle: 30
        tcp_keepalive_intvl: 10
        tcp_keepalive_cnt: 3

        # Reconnect backoff
        tcp_reconnect_backoff: 1

salt_minion_conf_beacon:
  file.managed:
    - name: {{ minion_conf_beacon }}
    - makedirs: True
    {%- if grains['os_family'] != 'Windows' %}
    - mode: '0644'
    {%- endif %}
    - contents: |
    {%- if grains['os_family'] != 'Windows' %}
        beacons:
          resolv_conf:
            - files:
                /etc/resolv.conf:
                  mask:
                    - modify
            - beacon_module: file_watch

          hosts_file:
            - files:
                /etc/hosts:
                  mask:
                    - modify
            - beacon_module: file_watch
    {%- else %}
        beacons:
          hosts_file:
            - files:
                C:/Windows/System32/drivers/etc/hosts:
                  mask:
                    - modify
            - beacon_module: windows_event_log
    {%- endif %}

salt_minion_conf_grains:
  file.managed:
    - name: {{ minion_conf_grains }}
    - makedirs: True
    {%- if grains['os_family'] != 'Windows' %}
    - mode: '0644'
    {%- endif %}
    - contents: |
        grains_refresh_pre_exec: True

salt_minion_conf_logging:
  file.managed:
    - name: {{ minion_conf_logging }}
    - contents: |
        log_granular_levels:
          'salt': 'error'
          'salt.modules': 'info'
          'salt.loaded.ext.module.custom_module': 'warning'
          'salt.loaded.ext.states.custom_module': 'warning'
          'salt.utils.schedule': 'error'
          'salt.beacons': 'error'

{%- for module in salt_modules %}
{#-
FIXME: we don't actually want to do this it breaks salts working state for onedir
  - Evaluate fallout and remediation for fleet
#}
# salt_minion_deps_{{ module }}:
#   pip.installed:
#     - name: {{ module }}

{%- endfor %}

# NOTE: restarting salt-minion during salt-call interrupts the run
# apply via master: salt '*' state.sls common.salt_minion
{%- set is_container = salt['file.file_exists']('/.dockerenv') or
                      salt['file.file_exists']('/run/.containerenv') %}
{%- if not is_container %}
salt_minion_service:
  service.running:
    - name: salt-minion
    - enable: True
  {%- if grains['os_family'] != 'Windows' %}
    - reload: True
  {%- endif %}
    - watch:
      - file: salt_minion_conf
      - file: salt_minion_conf_opt
      - file: salt_minion_conf_timeout
      - file: salt_minion_conf_logging

{%- endif %}
