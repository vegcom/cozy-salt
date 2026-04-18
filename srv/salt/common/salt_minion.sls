{%- set salt_master = salt['pillar.get']('salt:master', '') %}

{%- if grains['os_family'] == 'Windows' %}
  {%- set minion_conf_dir = 'C:\\salt\\conf\\' %}
  {%- set minion_conf = minion_conf_dir ~ '\\minion' %}
  {%- set minion_conf_opt = minion_conf_dir ~ '\\minion.d\\99-cozy.conf' %}
{%- else %}
  {%- set minion_conf_dir = '/etc/salt/' %}
  {%- set minion_conf = minion_conf_dir ~ '/minion' %}
  {%- set minion_conf_opt = minion_conf_dir ~ '/minion.d/99-cozy.conf' %}
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

# NOTE: restarting salt-minion during salt-call interrupts the run
# apply via master: salt '*' state.sls common.salt_minion
{% set is_container = salt['file.file_exists']('/.dockerenv') or
                      salt['file.file_exists']('/run/.containerenv') %}
{% if not is_container %}
salt_minion_service:
  service.running:
    - name: salt-minion
    - enable: True
    - watch:
      - file: salt_minion_conf
      - file: salt_minion_conf_opt
{% endif %}
