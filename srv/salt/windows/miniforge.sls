# Windows Miniforge system-wide installation
# Installs Miniforge3 to C:\opt\miniforge3 for all users
# Environment variables configured as system-wide for consistency
{% set miniforge_versions = salt['pillar.get']('versions:miniforge', {}) %}
{% set miniforge_version = miniforge_versions.get('version', '24.11.3-0') %}
{% set miniforge_path = 'C:\opt\miniforge3' %}
{% set miniforge_tmp = 'C:\Windows\Temp\miniforge-install.exe' %}
# Miniforge path
{% set miniforge_bin = 'C:\opt\miniforge3\Scripts' %}
# Save current reg entries
# ref: https://docs.saltproject.io/en/latest/ref/modules/all/salt.modules.reg.html#salt.modules.reg.set_value
{% set current_path = salt['reg.read_value']('HKLM', 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment', 'Path').get('vdata', '') %}

# Merge paths if absent
{% if miniforge_bin not in current_path.split(';') %}
  {% set merged_paths = current_path + ';' + miniforge_bin %}
{% else %}
  {% set merged_paths = current_path %}
{% endif %}

# Create C:\opt\miniforge3 directory for consistency
miniforge_directory:
  file.directory:
    # TODO: 'C:\opt\miniforge3' references to pillar
    - name: {{ miniforge_path }}
    - makedirs: True

# Download miniforge installer
miniforge_download:
  cmd.run:
    # XXX: Changed powershell to pwsh. powershell has no double ampersant or bar operator
    # XXX: $env:TEMP can not have single quotes
    - name: pwsh -Command "Invoke-WebRequest -Uri https://github.com/conda-forge/miniforge/releases/download/{{ miniforge_version }}/Miniforge3-Windows-x86_64.exe -OutFile {{ miniforge_tmp }}"
    # XXX: C:\Windows\Temp\ =/= $env:TEMP
    - creates: {{ miniforge_tmp }}
    - shell: pwsh
    - require:
      - file: miniforge_directory

# Install miniforge system-wide to C:\opt\miniforge3
miniforge_install:
  cmd.run:
    # XXX: Changed powershell to pwsh. powershell has no double ampersant or bar operator
    # XXX: $env:TEMP can not have single quotes
    # XXX: removed Remove-Item -Path {{ miniforge_tmp }} -Force
    # XXX: /AddToPath=1 is not allowed with all user installs
    # XXX: needs manual path add https://learn.microsoft.com/en-us/previous-versions/office/developer/sharepoint-2010/ee537574(v=office.14)#to-add-a-path-to-the-path-environment-variable
    # XXX: https://github.com/conda-forge/miniforge/blob/60ce0741ac3437a3d9fe35bb0ab5acfa6d8cc377/README.md#install
    - name: Start-Process cmd.exe -WindowStyle Hidden -ArgumentList "/C START /WAIT {{ miniforge_tmp }} /InstallationType=AllUsers /RegisterPython=1 /S /D=C:{{ miniforge_path }}"
    - shell: pwsh
    - require:
      - cmd: miniforge_download
    - creates: '{{ miniforge_path }}\Scripts\conda.exe'

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
    - require:
      - cmd: miniforge_install

# XXX https://docs.saltproject.io/en/latest/ref/modules/all/salt.modules.reg.html
miniforge_path_update:
  reg.present:
    - name: HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment
    - vname: Path
    - vtype: REG_EXPAND_SZ
    - value: "{{ merged_paths }}"


# Install base pip packages via common orchestration
include:
  - common.miniforge

