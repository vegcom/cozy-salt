# Windows Miniforge system-wide installation
# Installs Miniforge3 to C:\opt\miniforge3 for all users

{% set miniforge_versions = salt['pillar.get']('versions:miniforge', {}) %}
{% set miniforge_version  = miniforge_versions.get('version', '24.11.3-0') %}
{% set miniforge_path     = 'C:\\opt\\miniforge3' %}
{% set miniforge_tmp      = '$env:TEMP\\miniforge-install.exe' %}
{% set miniforge_bin      = 'C:\\opt\\miniforge3\\Scripts' %}
{% set current_path       = salt['reg.read_value']('HKLM',"SYSTEM\CurrentControlSet\Control\Session Manager\Environment",'Path').get('vdata','') %}

# FIX: Use proper list-based path merging to avoid duplicates
{% set paths = current_path.split(';') %}

{% if miniforge_bin not in paths %}
  {% do paths.append(miniforge_bin) %}
{% endif %}

{% if miniforge_path not in paths %}
  {% do paths.append(miniforge_path) %}
{% endif %}

{% set merged_paths = ';'.join(paths) %}

# Create C:\opt\miniforge3 directory for consistency
miniforge_directory:
  file.directory:
    - name: {{ miniforge_path }}
    - makedirs: True
    
# Download miniforge installer
miniforge_download:
  cmd.run:
    - name: >
        pwsh -NoLogo -NoProfile -Command
        "Invoke-WebRequest -Uri 'https://github.com/conda-forge/miniforge/releases/download/{{ miniforge_version }}/Miniforge3-Windows-x86_64.exe' -OutFile {{ miniforge_tmp }}"
    - creates: {{ miniforge_tmp }}
    - require:
      - file: miniforge_directory

miniforge_install:
  cmd.run:
    - name: >
        pwsh -NoLogo -NoProfile -Command
        "& \"$env:TEMP\miniforge-install.exe\" /InstallationType=AllUsers /RegisterPython=1 /S /D={{ miniforge_path }}"
    - creates: {{ miniforge_path }}\Scripts\conda.exe
    - require:
      - cmd: miniforge_download


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
    - name: HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment
    - vname: CONDA_HOME
    - vdata: {{ miniforge_path }}
    - vtype: REG_SZ
    - require:
      - cmd: miniforge_install
      - file: miniforge_directory

# XXX https://docs.saltproject.io/en/latest/ref/modules/all/salt.modules.reg.html
miniforge_path_update:
  reg.present:
    - name: HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment
    - vname: Path
    - vtype: REG_EXPAND_SZ
    - vdata: {{ merged_paths }}
    - require:
      - cmd: miniforge_install
      - file: miniforge_directory


# Install base pip packages via common orchestration
include:
  - common.miniforge