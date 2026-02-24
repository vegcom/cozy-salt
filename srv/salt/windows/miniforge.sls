# Windows Miniforge system-wide installation
# See docs/modules/windows-miniforge.md for configuration
# PATH updates handled by windows.paths (avoids race conditions)

{% set miniforge_versions = salt['pillar.get']('versions:miniforge', {}) %}
{% set miniforge_version  = miniforge_versions.get('version', '24.11.3-0') %}
{# Path configuration from pillar with defaults #}
{% set miniforge_path     = salt['pillar.get']('install_paths:miniforge:windows', 'C:\\opt\\miniforge3') %}
{% set miniforge_tmp      = '$env:TEMP\\miniforge-install.exe' %}
{% set env_registry = salt['pillar.get']('windows:env_registry', 'HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment') %}
{% set pwsh_7_profile = salt['pillar.get']('paths:powershell_7_profile', 'C:\\Program Files\\PowerShell\\7') %}

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
    - creates: {{ miniforge_tmp }}
    - require:
      - file: miniforge_directory

miniforge_install:
  cmd.run:
    - name: >
        pwsh -NoLogo -Command
        "& \"$env:TEMP\miniforge-install.exe\" /InstallationType=AllUsers /RegisterPython=1 /S /D={{ miniforge_path }}"
    - creates: {{ miniforge_path }}\Scripts\conda.exe
    - require:
      - cmd: miniforge_download
      - cmd: opt_acl_cozyusers


miniforge_clean:
  cmd.run:
    - name: Remove-Item -Path {{ miniforge_tmp }} -Force
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

# Install base pip packages via common orchestration
include:
  - common.miniforge
  - windows.paths
