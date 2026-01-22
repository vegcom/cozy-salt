{% set wt_versions = salt['pillar.get']('versions:wt', {}) %}
{% set wt_version  = wt_versions.get('version', '1.23.13503.0') %}
{% set wt_path     = 'C:\\opt\\wt' %}
{% set wt_bin      = 'C:\\opt\\wt\\terminal-' + wt_version %}
{% set wt_tmp      = '$env:TEMP\\wt-install.exe' %}

# Create C:\opt\wt directory for consistency
wt_directory:
  file.directory:
    - name: {{ wt_path }}
    - makedirs: True

# Download wt installer
wt_download:
  cmd.run:
    - name: >
        pwsh -NoLogo -Command
        "Invoke-WebRequest -Uri 'https://github.com/microsoft/terminal/releases/download/v{{ wt_version }}/Microsoft.WindowsTerminal_{{ wt_version }}_x64.zip' -OutFile '{{ wt_tmp }}'"
    - creates: {{ wt_tmp }}
    - require:
      - file: wt_directory

wt_install:
  cmd.run:
    - name: >
        pwsh -NoLogo -Command
        "Expand-Archive -Path {{ wt_tmp }} -DestinationPath {{ wt_path }} -Force"
    - creates: {{ wt_path }}
    - require:
      - cmd: wt_download

{% for item in ("wt.exe", "WindowsTerminal.exe") %}
{{ item | replace('.', '_') }}_symlink:
  file.symlink:
    - name: {{ wt_path }}\{{ item }}
    - target: {{ wt_bin }}\{{ item }}
    - user: Administrator
    - group: Administrators
    - require:
      - cmd: wt_install
{% endfor %}

# Install base pip packages via common orchestration
include:
  - windows.paths
