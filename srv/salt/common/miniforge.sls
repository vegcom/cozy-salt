# Common Miniforge/Conda package orchestration
# Installs pip packages in miniforge base environment (cross-platform)
# Platform-specific miniforge installation delegated to linux.miniforge or windows.miniforge

{% import_yaml "packages.sls" as packages %}

{# Path configuration from pillar with defaults - platform-specific #}
{% if grains['os_family'] == 'Windows' %}
{% set miniforge_path = salt['pillar.get']('install_paths:miniforge:windows', 'C:\\opt\\miniforge3') %}
{% set pip_bin = miniforge_path ~ '\\Scripts\\pip.exe' %}
{% else %}
{% set miniforge_path = salt['pillar.get']('install_paths:miniforge:linux', '/opt/miniforge3') %}
{% set pip_bin = miniforge_path ~ '/bin/pip' %}
{% endif %}

# Install pip base packages in miniforge base environment
{% for package in packages.get('pip_base', []) %}
install_pip_base_{{ package | replace('-', '_') }}:
  cmd.run:
    {% if grains['os_family'] == 'Windows' %}
    - name: {{ pip_bin }} install {{ package }}
    - shell: pwsh
    - unless: {{ pip_bin }} show {{ package }}
    - require:
      - cmd: miniforge_install
    {% else %}
    - name: {{ pip_bin }} install {{ package }}
    - unless: {{ pip_bin }} show {{ package }}
    - require:
      - cmd: miniforge_install
    {% endif %}
{% endfor %}
