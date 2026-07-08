# Windows Miniforge system-wide installation
# See docs/modules/windows-miniforge.md for configuration
# PATH updates handled by windows.paths (avoids race conditions)

{%- from "_macros/acl.sls" import cozy_acl %}
{%- set _pinned = salt['pillar.get']('versions:miniforge:version', '') %}
{%- set miniforge_version = _pinned or salt['github_release.latest']('conda-forge/miniforge') %}
{# Path configuration from pillar with defaults #}
{%- set miniforge_path = salt['pillar.get']('install_paths:miniforge:windows', 'C:/opt/miniforge3') %}
{%- set miniforge_tmp = 'C:/opt/cozy/cache/miniforge-install.exe' %}
{%- set env_registry = salt['pillar.get']('windows:env_registry', 'HKEY_LOCAL_MACHINE/SYSTEM/CurrentControlSet/Control/Session Manager/Environment') %}

# Create C:\opt\miniforge3 directory for consistency
miniforge_directory:
  file.directory:
    - name: {{ miniforge_path }}
    - makedirs: True
    - clean: False

# Download miniforge installer
miniforge_download:
  cmd.run:
    - name: >
        pwsh -NoLogo -Command
        "Invoke-WebRequest -Uri 'https://github.com/conda-forge/miniforge/releases/download/{{ miniforge_version }}/Miniforge3-Windows-x86_64.exe' -OutFile {{ miniforge_tmp }}"
    - shell: pwsh
    - require:
      - file: miniforge_directory

miniforge_install:
  cmd.run:
    - name: >
        pwsh -NoLogo -Command
        '& "{{ miniforge_tmp }}" /InstallationType=AllUsers /RegisterPython=1 /S /D={{ miniforge_path }}'
    - shell: pwsh
    - require:
      - cmd: miniforge_download

miniforge_clean:
  cmd.run:
    - name: >
        pwsh -NoLogo -Command
        "Remove-Item -Path {{ miniforge_tmp }} -Force"
    - shell: pwsh
    - require:
      - cmd: miniforge_install
      - file: miniforge_directory

# Set system-wide environment variable for Miniforge/Conda
miniforge_conda_home:
  reg.present:
    - name: {{ env_registry }}
    - vname: CONDA_HOME
    - vdata: {{ miniforge_path }}
    - vtype: REG_SZ
    - require:
      - cmd: miniforge_install
      - file: miniforge_directory

# Create pip data dir
pip_datadir:
  file.directory:
    - name: "C:/ProgramData/pip"
    - makedirs: True
    - clean: False

# Install base pip packages via common orchestration
include:
  - common.miniforge
  - windows.paths
