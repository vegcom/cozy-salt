# Windows Miniforge system-wide installation
# See docs/modules/windows-miniforge.md for configuration
# PATH updates handled by windows.paths (avoids race conditions)

{%- from "_macros/acl.sls" import cozy_acl %}
{%- set _pinned = salt['pillar.get']('versions:miniforge:version', '') %}
{%- set miniforge_version = _pinned or salt['github_release.latest']('conda-forge/miniforge', fallback="26.3.2-3") %}
{# Path configuration from pillar with defaults #}
{%- set miniforge_path = salt['pillar.get']('install_paths:miniforge:windows', 'C:/opt/miniforge3') %}
{%- set miniforge_tmp = 'C:/opt/cozy/cache/miniforge-install.exe' %}
{%- set env_registry = salt['pillar.get']('windows:env_registry', 'HKEY_LOCAL_MACHINE/SYSTEM/CurrentControlSet/Control/Session Manager/Environment') %}

# Miniforge will not install if path is present even if unpopulate
{%- set miniforge_dir_exists = salt['file.file_exists'](miniforge_path ~ '/condabin') %}
{%- if not miniforge_dir_exists %}
miniforge_directory:
  file.absent:
    - name: {{ miniforge_path }}
{%- else %}
miniforge_directory:
  test.nop:
      - name: "Valid install: `{{ miniforge_path }}/condabin` present"
{%- endif %}

# Download miniforge installer
miniforge_download:
  file.managed:
    - name: {{ miniforge_tmp }}
    - source: https://github.com/conda-forge/miniforge/releases/download/{{ miniforge_version }}/Miniforge3-Windows-x86_64.exe
    - skip_verify: True
    - mkdirs: True

miniforge_install:
  cmd.run:
    - name: >
        & "{{ miniforge_tmp }}" /InstallationType=AllUsers /RegisterPython=1 /S /D={{ miniforge_path | replace('/', '\\') }}
    - hide_output: True
    - output_loglevel: quiet
    - shell: powershell
    - require:
      - cmd: miniforge_download

# Set system-wide environment variable for Miniforge/Conda
miniforge_conda_home:
  reg.present:
    - name: {{ env_registry }}
    - vname: CONDA_HOME
    - vdata: {{ miniforge_path }}
    - vtype: REG_SZ
    - require:
      - cmd: miniforge_install

# Create pip data dir
pip_datadir:
  file.directory:
    - name: "C:/ProgramData/pip"
    - makedirs: True
    - clean: False

# Install base pip packages via common orchestration
include:
  - common.miniforge
