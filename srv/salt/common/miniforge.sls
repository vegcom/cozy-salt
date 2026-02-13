# Common Miniforge/Conda package orchestration

{% import_yaml "packages.sls" as packages %}
{% set service_user = salt['pillar.get']('managed_users', ['admin'])[0] %}
{% if grains['os_family'] == 'Windows' %}
  {% set miniforge_path = salt['pillar.get']('install_paths:miniforge:windows', 'C:\\opt\\miniforge3') %}
  {% set pip_bin = miniforge_path ~ '\\Scripts\\pip.exe' %}
  {% set uv_bin = miniforge_path ~ '\\Scripts\\uv.exe' %}
{% else %}
  {% set miniforge_path = salt['pillar.get']('install_paths:miniforge:linux', '/opt/miniforge3') %}
  {% set pip_bin = miniforge_path ~ '/bin/pip' %}
  {% set uv_bin = miniforge_path ~ '/bin/uv' %}
{% endif %}

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
