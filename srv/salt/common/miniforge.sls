#!jinja|yaml
# Common Miniforge/Conda package orchestration

{%- from '_macros/packages.sls' import get_packages %}
{%- from "_macros/acl.sls" import cozy_acl %}
{%- set packages = get_packages() | load_json %}
{%- set service_user = salt['pillar.get']('service_user:name', 'cozy-salt-svc') %}
{%- set python_version = salt['pillar.get']('miniforge:python:version', '3.12') %}
{%- if grains['os_family'] == 'Windows' %}
  {%- set miniforge_path = salt['pillar.get']('install_paths:miniforge:windows', 'C:/opt/miniforge3') %}
  {%- set pip_bin = miniforge_path ~ '/Scripts/pip.exe' %}
  {%- set uv_bin = miniforge_path ~ '/Scripts/uv.exe' %}
  {%- set conda_bin = miniforge_path ~ '/condabin/conda.bat' %}
  {%- set mamba_bin = miniforge_path ~ '/condabin/mamba.bat' %}
  {%- set pip_config_dest = salt['pillar.get']('config_paths:pip:windows') %}
  {%- set pip_cache = salt['pillar.get']('cache_paths:pip:windows') %}
  {%- set conda_envs = miniforge_path ~ '/envs' %}
  {%- set miniforge_mgr = conda_bin %}
  {%- set python_bin = miniforge_path ~ "/python" ~ python_version.replace(".","") ~ ".exe" %}
{%- else %}
  {%- set miniforge_path = salt['pillar.get']('install_paths:miniforge:linux', '/opt/miniforge3') %}
  {%- set pip_bin = miniforge_path ~ '/bin/pip' %}
  {%- set uv_bin = miniforge_path ~ '/bin/uv' %}
  {%- set conda_bin = miniforge_path ~ '/bin/conda' %}
  {%- set mamba_bin = miniforge_path ~ '/bin/mamba' %}
  {%- set pip_config_dest = salt['pillar.get']('config_paths:pip:linux') %}
  {%- set pip_cache = salt['pillar.get']('cache_paths:pip:linux') %}
  {%- set conda_envs = miniforge_path ~ '/envs' %}
  {%- set miniforge_mgr = mamba_bin %}
  {%- set python_bin = miniforge_path ~ "python" ~ python_version %}
{%- endif %}

{%- set pip_local_mirror = salt['pillar.get']('pip:local_mirror', '') %}
{%- set pip_cache_enabled = salt['pillar.get']('pip:cache_enabled', False) %}
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

conda_config:
  cmd.run:
    - names:
      - {{ conda_bin }} config --system --remove-key envs_dirs{%- if grains['os_family'] != 'Windows' -%}&>/dev/null||true {%- endif %}
      - {{ conda_bin }} config --system --add envs_dirs {{ conda_envs }}
    - success_retcodes:
      - 0
      - 2
    {%- if grains['os_family'] == 'Windows' %}
    - shell: powershell
    {%- endif %}

# Set default conda version
conda_base_version:
  cmd.run:
    - name: {{ miniforge_mgr }} install --quiet --yes python={{ python_version }}
    - hide_output: True
    - output_loglevel: quiet
    - require:
      - cmd: miniforge_install
      - cmd: conda_config
    {%- if grains['os_family'] == 'Windows' %}
    - shell: powershell
    - unless: Test-Path {{ python_bin }}
    {%- else %}
    - unless: test -f {{ python_bin }}
    {%- endif %}

# Install pip base packages in miniforge base environment
{%- for package in packages.get('pip_base', []) %}

{%- if pip_cache_enabled %}
# Cache base environment
cache_pip_base_{{ package | replace('-', '_') }}:
  cmd.run:
    # TODO: platform pillar presently disabled as we find most viable args
    - name: {{ mamba_bin }} run pip download {%- if pip_architectures|length > 1 %} {%- for arch in pip_architectures %} --platform {{ arch }} {%- endfor %} {%- endif %} --dest {{ pip_cache }} --pre --index-url https://pypi.org/simple {{ package }}
    - hide_output: True
    - output_loglevel: quiet
    - order: 0
    {%- if grains['os_family'] == 'Windows' %}
    - shell: powershell
    {%- endif %}
    - require:
      - cmd: miniforge_install
      - cmd: conda_base_version
{%- endif %}

install_pip_base_{{ package | replace('-', '_') }}:
  cmd.run:
    - name: {{ miniforge_mgr }} install --quiet --yes --name base {{ package }}
    - hide_output: True
    - output_loglevel: quiet
    - order: 1
    - unless: {{ pip_bin }} show {{ package }}
    {%- if grains['os_family'] == 'Windows' %}
    - shell: powershell
    {%- endif %}
    - require:
      - cmd: miniforge_install
      - cmd: conda_base_version
{%- endfor %}

# Set ACLs for cozyusers group access
{%- set pip_base_pkg = [] %}
{%- for package in packages.get('pip_base', []) %}
  {%- do pip_base_pkg.append('cmd: install_pip_base_' ~ package|replace('-', '_')) %}
{%- endfor %}
{%- set miniforge_deps = ['cmd: miniforge_install', 'cmd: conda_base_version'] + pip_base_pkg %}

{{ cozy_acl(
  miniforge_path,
  requires=miniforge_deps,
) }}
