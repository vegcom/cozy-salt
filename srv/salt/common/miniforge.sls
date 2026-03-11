# Common Miniforge/Conda package orchestration

{% import_yaml "packages.sls" as packages %}
{%- set service_user = salt['pillar.get']('service_user:name', 'cozy-salt-svc') %}
{% if grains['os_family'] == 'Windows' %}
  {% set miniforge_path = salt['pillar.get']('install_paths:miniforge:windows', 'C:\\opt\\miniforge3') %}
  {% set pip_bin = miniforge_path ~ '\\Scripts\\pip.exe' %}
  {% set uv_bin = miniforge_path ~ '\\Scripts\\uv.exe' %}
  {% set pip_config_dest = salt['pillar.get']('config_paths:pip:windows') %}
  {% set pip_cache = salt['pillar.get']('cache_paths:pip:windows') %}
{% else %}
  {% set miniforge_path = salt['pillar.get']('install_paths:miniforge:linux', '/opt/miniforge3') %}
  {% set pip_bin = miniforge_path ~ '/bin/pip' %}
  {% set uv_bin = miniforge_path ~ '/bin/uv' %}
  {% set pip_config_dest = salt['pillar.get']('config_paths:pip:linux') %}
  {% set pip_cache = salt['pillar.get']('cache_paths:pip:linux') %}
{% endif %}
{% set pip_local_mirror = salt['pillar.get']('pip:local_mirror', '') %}

# Install pip base packages in miniforge base environment
{% for package in packages.get('pip_base', []) %}
install_pip_base_{{ package | replace('-', '_') }}:
  cmd.run:
    - name: {{ pip_bin }} install {{ package }}
    {% if grains['os_family'] == 'Windows' %}
    - shell: pwsh
    - require:
      - cmd: miniforge_install
      - cmd: opt_acl_cozyusers
    {% else %}
    - require:
      - cmd: miniforge_install
    {% endif %}
    - runas: {{ service_user }}
    - unless: {{ pip_bin }} show {{ package }}
{% endfor %}

{% if grains['os_family'] != 'Windows' %}
# Fix miniforge3 permissions for managed user to install packages
miniforge_permissions:
  file.directory:
    - name: {{ miniforge_path }}
    - user: {{ service_user }}
    - group: cozyusers
    - dir_mode: "0775"
    - recurse:
      - user
      - group
    - require:
      - cmd: miniforge_install
{% for package in packages.get('pip_base', []) %}
      - cmd: install_pip_base_{{ package | replace('-', '_') }}
{% endfor %}
{% endif %}

pip_config:
  file.managed:
    - name: {{ pip_config_dest }}
    - source: salt://_templates/pip.jinja
    - template: jinja
    - makedirs: True
    - mode: '0644'
    - cache_path: {{ pip_cache }}
    - local_mirror: {{ pip_local_mirror }}
