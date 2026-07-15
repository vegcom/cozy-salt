{%- set _pinned = salt['pillar.get']('versions:windhawk:version', '') %}
{%- set windhawk_version = _pinned or salt['github_release.latest']('ramensoftware/windhawk') or '1.7.3' %}
{%- set windhawk_path = 'C:\\opt\\windhawk' %}
{%- set windhawk_tmp = 'C:/opt/cozy/cache/windhawk-install.exe' %}

# Create C:\opt\windhawk directory for consistency
windhawk_directory:
  file.directory:
    - name: {{ windhawk_path }}
    - makedirs: True

# Download windhawk installer
windhawk_download:
  cmd.run:
    - name: >
        pwsh -NoLogo -Command
        "Invoke-WebRequest -Uri 'https://github.com/ramensoftware/windhawk/releases/download/v{{ windhawk_version }}/windhawk_setup.exe' -OutFile {{ windhawk_tmp }}"
    - require:
      - file: windhawk_directory

windhawk_install:
  cmd.run:
    - name: >
        pwsh -NoLogo -Command
        "& \"C:/opt/cozy/cache/windhawk-install.exe\" /S /AUTO_UPDATE /PORTABLE /D={{ windhawk_path }}"
    - require:
      - cmd: windhawk_download

# Install base pip packages via common orchestration
include:
  - windows.paths
