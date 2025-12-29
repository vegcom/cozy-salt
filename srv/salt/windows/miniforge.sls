# Windows Miniforge per-user installation
# Installs Miniforge3 to C:\Users\{USERNAME}\miniforge3

{% set user = salt['pillar.get']('user:name', 'Administrator') %}
{% set user_home = 'C:\\Users\\' ~ user %}
{% set miniforge_path = user_home ~ '\\miniforge3' %}

# Download miniforge installer
miniforge_download:
  cmd.run:
    - name: |
        powershell -Command "
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri 'https://github.com/conda-forge/miniforge/releases/download/24.11.3-0/Miniforge3-Windows-x86_64.exe' -OutFile '$env:TEMP\miniforge-install.exe'
        "
    - creates: C:\Windows\Temp\miniforge-install.exe
    - shell: powershell

# Install miniforge to user home directory
miniforge_install:
  cmd.run:
    - name: |
        powershell -Command "
        & '$env:TEMP\miniforge-install.exe' /InstallationType=JustMe /RegisterPython=0 /AddToPath=1 /D='{{ user_home }}\miniforge3' /S
        Remove-Item -Path '$env:TEMP\miniforge-install.exe' -Force -ErrorAction SilentlyContinue
        "
    - shell: powershell
    - require:
      - cmd: miniforge_download
    - unless: Test-Path '{{ user_home }}\miniforge3\Scripts\conda.exe'

# Initialize conda for PowerShell
miniforge_init_powershell:
  cmd.run:
    - name: |
        powershell -Command "
        & '{{ user_home }}\miniforge3\Scripts\conda.exe' init powershell
        "
    - shell: powershell
    - require:
      - cmd: miniforge_install
    - unless: powershell -Command "if (Test-Path $PROFILE) { Select-String -Path $PROFILE -Pattern 'conda initialize' -Quiet } else { $false }"

# Initialize conda for cmd
miniforge_init_cmd:
  cmd.run:
    - name: |
        powershell -Command "
        & '{{ user_home }}\miniforge3\Scripts\conda.exe' init cmd.exe
        "
    - shell: powershell
    - require:
      - cmd: miniforge_install
