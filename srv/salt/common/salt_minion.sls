{%- set salt_master = salt['pillar.get']('salt:master', '') %}

{%- if grains['os_family'] == 'Windows' %}
  {%- set minion_conf_dir = 'C:/salt/conf/' %}
{%- else %}
  {%- set minion_conf_dir = '/etc/salt/' %}
{%- endif %}

{%- set minion_conf = minion_conf_dir ~ '/minion' %}
{%- set minion_conf_beacon = minion_conf_dir ~ '/minion.d/97-beacon.conf' %}
{%- set minion_conf_timeout = minion_conf_dir ~ '/minion.d/98-timeout.conf' %}
{%- set minion_conf_opt = minion_conf_dir ~ '/minion.d/99-cozy.conf' %}

{%- set minion_conf_obj = "default_include: " ~ "minion.d/*.conf" ~ "\n" %}

{%- if grains['os_family'] != 'Windows' %}
  {%- set salt_modules = salt['pillar.get']('salt:modules:linux', ["pyinotify", "gitpython", "pymongo", "psycopg2"]) %}
{%- else %}
  {%- set salt_modules = salt['pillar.get']('salt:modules:windows', ["gitpython", "pymongo", "psycopg2"]) %}
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
        tcp_reconnect_backoff: 1
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

{%- for module in salt_modules %}

salt_minion_deps_{{ module }}:
  pip.installed:
    - name: {{ module }}
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
    - watch:
      - file: salt_minion_conf
      - file: salt_minion_conf_opt
      - file: salt_minion_conf_timeout
{%- endif %}
