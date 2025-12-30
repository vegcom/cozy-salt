# Windows Miniforge system-wide installation
# Installs Miniforge3 to C:\opt\miniforge3 for all users
# Environment variables configured as system-wide for consistency

{% set miniforge_versions = salt['pillar.get']('versions:miniforge', {}) %}
{% set miniforge_version = miniforge_versions.get('version', '24.11.3-0') %}
{% set miniforge_path = 'C:\\opt\\miniforge3' %}

# Download miniforge installer
miniforge_download:
  cmd.run:
    - name: |
        powershell -Command "
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri 'https://github.com/conda-forge/miniforge/releases/download/{{ miniforge_version }}/Miniforge3-Windows-x86_64.exe' -OutFile '$env:TEMP\miniforge-install.exe'
        "
    - creates: C:\Windows\Temp\miniforge-install.exe
    - shell: powershell

# Install miniforge system-wide to C:\opt\miniforge3
miniforge_install:
  cmd.run:
    - name: |
        powershell -Command "
        & '$env:TEMP\miniforge-install.exe' /InstallationType=AllUsers /RegisterPython=1 /AddToPath=1 /D='{{ miniforge_path }}' /S
        Remove-Item -Path '$env:TEMP\miniforge-install.exe' -Force -ErrorAction SilentlyContinue
        "
    - shell: powershell
    - require:
      - cmd: miniforge_download
    - unless: Test-Path '{{ miniforge_path }}\Scripts\conda.exe'

# Set system-wide environment variable for Miniforge/Conda
miniforge_conda_home:
  reg.present:
    - name: HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment
    - vname: CONDA_HOME
    - vdata: C:\opt\miniforge3
    - vtype: REG_SZ
    - require:
      - cmd: miniforge_install
