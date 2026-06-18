# Common Miniforge/Conda package orchestration

{%- import_yaml "packages.sls" as packages %}
{%- set service_user = salt['pillar.get']('service_user:name', 'cozy-salt-svc') %}
{%- if grains['os_family'] == 'Windows' %}
  {%- set miniforge_path = salt['pillar.get']('install_paths:miniforge:windows', 'C:\\opt\\miniforge3') %}
  {%- set pip_bin = miniforge_path ~ '\\Scripts\\pip.exe' %}
  {%- set uv_bin = miniforge_path ~ '\\Scripts\\uv.exe' %}
  {%- set pip_config_dest = salt['pillar.get']('config_paths:pip:windows') %}
  {%- set pip_cache = salt['pillar.get']('cache_paths:pip:windows') %}
{%- else %}
  {%- set miniforge_path = salt['pillar.get']('install_paths:miniforge:linux', '/opt/miniforge3') %}
  {%- set pip_bin = miniforge_path ~ '/bin/pip' %}
  {%- set uv_bin = miniforge_path ~ '/bin/uv' %}
  {%- set pip_config_dest = salt['pillar.get']('config_paths:pip:linux') %}
  {%- set pip_cache = salt['pillar.get']('cache_paths:pip:linux') %}
{%- endif %}
{%- set pip_local_mirror = salt['pillar.get']('pip:local_mirror', '') %}

{%- if grains['os_family'] == 'Windows' %}
pip_config_path:
  file.directory:
    - name: {{ salt['file.dirname'](pip_config_dest) }}
    - makedirs: True
{%- endif %}

pip_config:
  file.managed:
    - name: {{ pip_config_dest }}
    - source: salt://_templates/pip.jinja
    - template: jinja
    - makedirs: True
    {%- if grains['os_family'] != 'Windows' %}
    - mode: '0644'
    {%- endif %}
    - cache_path: {{ pip_cache }}
    - local_mirror: {{ pip_local_mirror }}
  {%- if grains['os_family'] == 'Windows' %}
    - require:
      - file: pip_config_path
  {%- endif %}

# Install pip base packages in miniforge base environment
{%- for package in packages.get('pip_base', []) %}

# Cache base environment
cache_pip_base_{{ package | replace('-', '_') }}:
  cmd.run:
    - name: {{ pip_bin }} download -d {{ pip_cache }} {{ package }}
    - order: 0
    {%- if grains['os_family'] == 'Windows' %}
    - shell: pwsh
    - require:
      - cmd: miniforge_install
      - cmd: opt_acl_cozyusers
    {%- else %}
    - require:
      - cmd: miniforge_install
    {%- endif %}

install_pip_base_{{ package | replace('-', '_') }}:
  cmd.run:
    - name: {{ pip_bin }} install {{ package }}
    - order: 1
    {%- if grains['os_family'] == 'Windows' %}
    - shell: pwsh
    - require:
      - cmd: miniforge_install
      - cmd: opt_acl_cozyusers
    {%- else %}
    - require:
      - cmd: miniforge_install
    {%- endif %}
    - runas: {{ service_user }}
    - unless: {{ pip_bin }} show {{ package }}

{%- endfor %}
