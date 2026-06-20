{%- set salt_master = salt['pillar.get']('salt:master', '') %}

{%- if grains['os_family'] == 'Windows' %}
  {%- set minion_conf_dir = 'C:\\salt\\conf\\' %}
  {%- set minion_conf = minion_conf_dir ~ '\\minion' %}
  {%- set minion_conf_opt = minion_conf_dir ~ '\\minion.d\\99-cozy.conf' %}
  {%- set minion_conf_timeout = minion_conf_dir ~ '\\minion.d\\98-timeout.conf' %}
{%- else %}
  {%- set minion_conf_dir = '/etc/salt/' %}
  {%- set minion_conf = minion_conf_dir ~ '/minion' %}
  {%- set minion_conf_opt = minion_conf_dir ~ '/minion.d/99-cozy.conf' %}
  {%- set minion_conf_timeout = minion_conf_dir ~ '/minion.d/98-timeout.conf' %}
{%- endif %}

{%- set minion_conf_obj = "default_include: " ~ "minion.d/*.conf" ~ "\n" %}

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
    - mode: '0644'
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
