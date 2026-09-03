{%- set is_container = salt['file.file_exists']('/.dockerenv') or salt['file.file_exists']('/run/.containerenv') %}
{%- set ssh_enabled = salt['pillar.get']('host:capabilities:sshd', not is_container) %}
{%- if ssh_enabled %}
{#- Should be `salt://_templates/sshd_<name>.conf.jinja` #}
{%- set includes = ["hardening", "environment", "banner", "connection", "auth"] %}
  {%- set ssh_service_name = 'sshd' if grains['os_family'] in ['Arch', 'Windows', 'RedHat'] else 'ssh' %}
  {%- set paths = salt['pillar.get']('paths', {}) %}
  {%- if grains['os_family'] == 'Windows' -%}
    {%- set sshd_config_path = paths.get('sshd_config', 'C:/ProgramData/ssh') %}
    {%- set sshd_opt_include = paths.get('sshd_opt_path', 'C:/opt/cozy/etc/sshd_config_d') %}
  {%- else %}
    {%- set sshd_config_path = paths.get('sshd_config', '/etc/ssh') %}
    {%- set sshd_opt_include = paths.get('sshd_opt_path', '/opt/cozy/etc/sshd_config_d') %}
  {%- endif %}
  {%- set sshd_config = sshd_config_path ~ '/sshd_config' %}
  {%- set sshd_config_d = sshd_config_path ~ '/sshd_config.d' %}
{#- `srv/salt/_templates/sshd_config.jinja` #}
sshd_config:
  file.managed:
    - name: {{ sshd_config }}
    - source: salt://_templates/sshd_config.jinja
    - template: jinja
    - makedirs: True
{%- set start = 99 %}
{%- for idx in range(includes|length) %}
sshd_{{ includes[idx] }}_config:
  file.managed:
    - name: {{ sshd_config_d }}/{{ start - idx }}-{{ includes[idx] }}.conf
    - source: salt://_templates/sshd_{{ includes[idx] }}.conf.jinja
    - template: jinja
    - makedirs: True
{%- endfor %}
sshd_service:
  service.running:
    - name: {{ ssh_service_name }}
    - enable: True
    - watch:
      - file: sshd_config
  {%- for inc in includes %}
      - file: sshd_{{ inc }}_config
  {%- endfor %}
{%- else %}
sshd_config:
  test.nop:
    - name: SSH config disabled:(host:capabilities:sshd = false)
{%- endif %}
