# Common Miniforge/Conda package orchestration

{% import_yaml "packages.sls" as packages %}
{% if grains['os_family'] == 'Windows' %}
  {% set miniforge_path = salt['pillar.get']('install_paths:miniforge:windows', 'C:\\opt\\miniforge3') %}
  {% set pip_bin = miniforge_path ~ '\\Scripts\\pip.exe' %}
  {% set uv_bin = miniforge_path ~ '\\Scripts\\uv.exe' %}
{% else %}
  {% set miniforge_path = salt['pillar.get']('install_paths:miniforge:linux', '/opt/miniforge3') %}
  {% set pip_bin = miniforge_path ~ '/bin/pip' %}
  {% set uv_bin = miniforge_path ~ '/bin/uv' %}
{% endif %}

{% if grains['os_family'] != 'Windows' %}
# Fix miniforge3 permissions for admin user to install packages
miniforge_permissions:
  file.directory:
    - name: {{ miniforge_path }}
    - user: admin
    - group: cozyusers
    - recurse:
      - user
      - group
    - require:
      - cmd: miniforge_install
{% endif %}

# Install uvx packages in miniforge base environment
install_pip_uv:
  cmd.run:
    - name: {{ pip_bin }} install uv
    {% if grains['os_family'] == 'Windows' %}
    - runas: SYSTEM
    - shell: pwsh
    {% else %}
    - runas: admin
    {% endif %}
    - unless: {{ pip_bin }} show uv
    - require:
      - cmd: miniforge_install
      {% if grains['os_family'] != 'Windows' %}
      - file: miniforge_permissions
      {% endif %}

# Install pip base packages in miniforge base environment
{% for package in packages.get('pip_base', []) %}
install_pip_base_{{ package | replace('-', '_') }}:
  cmd.run:
    - name: {{ uv_bin }} pip install --system --no-progress {{ package }}
    {% if grains['os_family'] == 'Windows' %}
    - shell: pwsh
    {% else %}
    - runas: admin
    {% endif %}
    - unless: {{ uv_bin }} pip show --system {{ package }}
    - require:
      - cmd: miniforge_install
{% endfor %}
