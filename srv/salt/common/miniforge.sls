#!jinja|yaml
# Common Miniforge/Conda package orchestration

{%- from '_macros/packages.sls' import get_packages %}
{%- from "_macros/acl.sls" import cozy_acl %}
{%- set packages = get_packages() | load_json %}
{%- set service_user = salt['pillar.get']('service_user:name', 'cozy-salt-svc') %}
{%- if grains['os_family'] == 'Windows' %}
  {%- set miniforge_path = salt['pillar.get']('install_paths:miniforge:windows', 'C:/opt/miniforge3') %}
  {%- set pip_bin = miniforge_path ~ '/Scripts/pip.exe' %}
  {%- set uv_bin = miniforge_path ~ '/Scripts/uv.exe' %}
  {%- set conda_bin = miniforge_path ~ '/condabin/conda.bat' %}
  {%- set mamba_bin = miniforge_path ~ '/condabin/mamba.bat' %}
  {%- set pip_config_dest = salt['pillar.get']('config_paths:pip:windows') %}
  {%- set pip_cache = salt['pillar.get']('cache_paths:pip:windows') %}
{%- else %}
  {%- set miniforge_path = salt['pillar.get']('install_paths:miniforge:linux', '/opt/miniforge3') %}
  {%- set pip_bin = miniforge_path ~ '/bin/pip' %}
  {%- set uv_bin = miniforge_path ~ '/bin/uv' %}
  {%- set conda_bin = miniforge_path ~ '/bin/conda' %}
  {%- set mamba_bin = miniforge_path ~ '/bin/mamba' %}
  {%- set pip_config_dest = salt['pillar.get']('config_paths:pip:linux') %}
  {%- set pip_cache = salt['pillar.get']('cache_paths:pip:linux') %}
{%- endif %}
{%- set pip_local_mirror = salt['pillar.get']('pip:local_mirror', '') %}
{%- set pip_architectures = salt['pillar.get']('pip:architectures', []) %}

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

# Update conda base
conda_base_update:
  cmd.run:
    - name: >
        {{ mamba_bin }} --use-uv update
    {%- if grains['os_family'] == 'Windows' %}
    - shell: pwsh
    {%- endif %}
    - require:
      - cmd: miniforge_install
      - file: pip_config

# Set default conda version
conda_base_version:
  cmd.run:
    - name: {{ mamba_bin }} --use-uv install python=3.12
    {%- if grains['os_family'] == 'Windows' %}
    - shell: pwsh
    {%- endif %}
    - require:
      - cmd: miniforge_install
    - onchanges:
      - cmd: miniforge_install
      - cmd: conda_base_update

# Install pip base packages in miniforge base environment
{%- for package in packages.get('pip_base', []) %}

# Cache base environment
cache_pip_base_{{ package | replace('-', '_') }}:
  cmd.run:
    # TODO: platform pillar presently disabled as we find most viable args
    - name: {{ mamba_bin }} --use-uv run pip download {%- if pip_architectures|length > 1 %} {%- for arch in pip_architectures %} --platform {{ arch }} {%- endfor %} {%- endif %} --dest {{ pip_cache }} --pre --index-url https://pypi.org/simple {{ package }}
    - hide_output: True
    - order: 0
    {%- if grains['os_family'] == 'Windows' %}
    - shell: pwsh
    {%- endif %}
    - require:
      - cmd: miniforge_install
      - cmd: conda_base_version

install_pip_base_{{ package | replace('-', '_') }}:
  cmd.run:
    - name: {{ mamba_bin }} --use-uv install {{ package }}
    - hide_output: True
    - order: 1
    - unless: {{ pip_bin }} show {{ package }}
    {%- if grains['os_family'] == 'Windows' %}
    - shell: pwsh
    {%- endif %}
    - onchanges:
      - cmd: miniforge_install
    - require:
      - cmd: miniforge_install
      - cmd: conda_base_version
{%- endfor %}

# Set ACLs for cozyusers group access
{%- set pip_onchanges = [] %}
{%- for package in packages.get('pip_base', []) %}
  {%- do pip_onchanges.append('cmd: install_pip_base_' ~ package|replace('-', '_')) %}
{%- endfor %}

{{ cozy_acl(
  miniforge_path,
  requires=['cmd: miniforge_install'],
  onchanges=pip_onchanges
) }}
