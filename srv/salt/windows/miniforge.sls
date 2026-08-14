# Windows Miniforge system-wide installation
# See docs/modules/windows-miniforge.md for configuration
# PATH updates handled by windows.paths (avoids race conditions)

{%- set _pinned = salt['pillar.get']('versions:miniforge:version', '') %}
{%- set miniforge_version = _pinned or salt['github_release.latest']('conda-forge/miniforge', fallback="26.3.2-3") %}
{# Path configuration from pillar with defaults #}
{%- set miniforge_path = salt['pillar.get']('install_paths:miniforge:windows', 'C:/opt/miniforge3') %}
{%- set miniforge_tmp = 'C:/opt/cozy/cache/miniforge-install.exe' %}
{%- set env_registry = salt['pillar.get']('windows:env_registry', 'HKEY_LOCAL_MACHINE/SYSTEM/CurrentControlSet/Control/Session Manager/Environment') %}
{%- set conda_envs = miniforge_path ~ '/envs' %}

{%- set miniforge_file_exists = salt['file.file_exists'](miniforge_path ~ '/condabin/conda.bat') %}

{%- set conda_validate = salt['cmd.retcode']('if (& "' ~ miniforge_path ~ '/condabin/conda.bat" --version 2>&1 | Select-String "ModuleNotFoundError") { $host.SetShouldExit(1); exit 1 } else { exit 0 }', shell="powershell") %}
{%- set miniforge_force = true if conda_validate == 1 else salt['pillar.get']('miniforge_force', false) %}

# Miniforge will not install if path is present even if unpopulated
{%- if not miniforge_file_exists or miniforge_force %}
miniforge_directory:
  file.directory:
    - name: {{ miniforge_path }}
    - clean: true
  {%- if not miniforge_force %}
    - onlyif: powershell -NoProfile -Command "Test-Path '{{ miniforge_path }}'"
    - unless: powershell -NoProfile -Command "Test-Path '{{ miniforge_path }}\condabin'"
  {%- endif %}
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
    - name: 'start /wait "" "{{ miniforge_tmp }}" /S /InstallationType=AllUsers /RegisterPython=1 /D={{ miniforge_path | replace("/", "\\") }}'
    - shell: cmd
    - order: 0
    - require:
      - file: miniforge_download
{%- if not miniforge_file_exists or miniforge_force %}
      - file: miniforge_directory
{%- endif %}

# Set system-wide environment variables for Miniforge/Conda
miniforge_conda_home:
  reg.present:
    - name: {{ env_registry }}
    - vname: CONDA_HOME
    - vdata: {{ miniforge_path }}
    - vtype: REG_SZ
    - require:
      - cmd: miniforge_install

miniforge_conda_envs:
  reg.present:
    - name: {{ env_registry }}
    - vname: CONDA_ENVS_DIRS
    - vdata: {{ conda_envs }}
    - vtype: REG_SZ
    - require:
      - cmd: miniforge_install

# Create pip data dir
pip_datadir:
  file.directory:
    - name: "C:/ProgramData/pip"
    - makedirs: True
    - clean: False

{%- if miniforge_file_exists %}
# Install base pip packages via common orchestration
include:
  - common.miniforge
  - windows.paths
extend:
  conda_config:
    cmd.run:
      - require:
        - cmd: miniforge_install
{%- endif %}
