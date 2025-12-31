# Windows Miniforge system-wide installation
# Installs Miniforge3 to C:\opt\miniforge3 for all users
# Environment variables configured as system-wide for consistency
# Save current reg entries
# ref: https://docs.saltproject.io/en/latest/ref/modules/all/salt.modules.reg.html#salt.modules.reg.set_value
{# set current_path = salt['reg.read_value']('HKLM',"SYSTEM\CurrentControlSet\Control\Session Manager\Environment",'Path').get('vdata','').replace('%', '\\%') #}

{% set miniforge_versions = salt['pillar.get']('versions:miniforge', {}) %}
{% set miniforge_version  = miniforge_versions.get('version', '24.11.3-0') %}
{% set miniforge_path     = 'C:\\opt\\miniforge3' %}
{% set miniforge_tmp      = '$env:TEMP\\miniforge-install.exe' %}
{% set miniforge_bin      = 'C:\\opt\\miniforge3\\Scripts' %}
{% set current_path       = salt['reg.read_value']('HKLM',"SYSTEM\CurrentControlSet\Control\Session Manager\Environment",'Path').get('vdata','') %}


# Merge paths if absent
{% if miniforge_bin not in current_path.split(';') %}
  {% set merged_paths = current_path + ';' + miniforge_bin %}
{% else %}
  {% set merged_paths = current_path %}
{% endif %}

# Create C:\opt\miniforge3 directory for consistency
miniforge_directory:
  file.directory:
    - name: {{ miniforge_path }}
    - makedirs: True
    

# Download miniforge installer
# XXX: Changed powershell to pwsh. powershell has no double ampersant or bar operator
# XXX: $env:TEMP can not have single quotes
# Download miniforge installer
miniforge_download:
  cmd.run:
    - name: >
        pwsh -NoLogo -NoProfile -Command
        "Invoke-WebRequest -Uri 'https://github.com/conda-forge/miniforge/releases/download/{{ miniforge_version }}/Miniforge3-Windows-x86_64.exe' -OutFile {{ miniforge_tmp }}"
    - creates: {{ miniforge_tmp }}
    - require:
      - file: miniforge_directory


# Install miniforge system-wide to C:\opt\miniforge3
# XXX: Changed powershell to pwsh. powershell has no double ampersant or bar operator
# XXX: $env:TEMP can not have single quotes
# XXX: removed Remove-Item -Path {{ miniforge_tmp }} -Force
# XXX: /AddToPath=1 is not allowed with all user installs
# XXX: needs manual path add https://learn.microsoft.com/en-us/previous-versions/office/developer/sharepoint-2010/ee537574(v=office.14)#to-add-a-path-to-the-path-environment-variable
# XXX: https://github.com/conda-forge/miniforge/blob/60ce0741ac3437a3d9fe35bb0ab5acfa6d8cc377/README.md#install
miniforge_install:
  cmd.run:
    - name: > 
        pwsh -NoLogo -NoProfile -Command 
        "'{{ miniforge_tmp }}' /Installation Type=AllUsers /RegisterPython=1 /S /D={{ miniforge_path }}"
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
    - name: HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session\ Manager\Environment
    - vname: Path
    - vtype: REG_EXPAND_SZ
    - vdata: {{ merged_paths }}
    - require:
      - cmd: miniforge_install
      - file: miniforge_directory


# Install base pip packages via common orchestration
include:
  - common.miniforge
