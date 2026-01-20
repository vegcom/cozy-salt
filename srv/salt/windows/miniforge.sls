# Windows Miniforge system-wide installation
# Installs Miniforge3 to C:\opt\miniforge3 for all users
# PATH updates handled by windows.paths (avoids race conditions)

{% set miniforge_versions = salt['pillar.get']('versions:miniforge', {}) %}
{% set miniforge_version  = miniforge_versions.get('version', '24.11.3-0') %}
{# Path configuration from pillar with defaults #}
{% set miniforge_path     = salt['pillar.get']('install_paths:miniforge:windows', 'C:\\opt\\miniforge3') %}
{% set miniforge_tmp      = '$env:TEMP\\miniforge-install.exe' %}
{% set env_registry = salt['pillar.get']('windows:env_registry', 'HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment') %}

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

# Initialize conda for PowerShell in system-wide profile
# Appends conda-hook.ps1 sourcing to AllUsersAllHosts profile (pwsh7)
miniforge_powershell_profile:
  file.append:
    - name: C:\Program Files\PowerShell\7\profile.ps1
    - text: |
        # Conda initialization (managed by Salt)
        if (Test-Path "{{ miniforge_path }}\shell\condabin\conda-hook.ps1") {
            . "{{ miniforge_path }}\shell\condabin\conda-hook.ps1"
        }
    - makedirs: True
    # - unless: 'pwsh -NoProfile -Command "Test-Path ''C:\Program Files\PowerShell\7\profile.ps1'' -and (Get-Content ''C:\Program Files\PowerShell\7\profile.ps1'' -Raw) -match ''conda-hook''"'
    - require:
      - cmd: miniforge_install
      - cmd: powershell_profile_deployed

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
