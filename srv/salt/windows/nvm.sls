# Windows Node.js version management via nvm-windows
# System-wide installation to C:\opt\nvm (consistent with Linux /opt/nvm)
{%- from "_macros/windows.sls" import win_cmd %}
{%- set nvm_config = salt['pillar.get']('nvm', {}) %}
{%- set nvm_version = nvm_config.get('default_version', 'lts') %}
{%- set _pinned_nvm_win = salt['pillar.get']('versions:nvm_windows:version', '') %}
{%- set nvm_win_version = _pinned_nvm_win or salt['github_release.latest']('coreybutler/nvm-windows', fallback="1.2.2") %}
{%- set npm_pkg = "https://github.com/coreybutler/nvm-windows/releases/download/" ~ nvm_win_version ~ "/nvm-noinstall.zip" %}
{%- set nvm_tmp = "C:/opt/cozy/cache/nvm-noinstall.zip" %}
{# Path configuration from pillar with defaults #}
{%- set nvm_path = salt['pillar.get']('install_paths:nvm:windows', 'C:\\opt\\nvm') %}
{%- set nvm_bin = nvm_path ~ '\\nvm.exe' %}
{%- set npm_settings = nvm_path ~ '\\settings.txt' %}
{%- set node_path = nvm_path ~ '\\nodejs' %}
{%- set env_registry = salt['pillar.get']('windows:env_registry', 'HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment') %}

nvm_install:
  archive.extracted:
    - name: {{ nvm_path }}
    - source: {{ npm_pkg }}
    - skip_verify: True
    - enforce_toplevel: False

nvm_npm_settings:
  file.managed:
    - name: {{ npm_settings }}
    - contents:
      - 'root: {{ nvm_path }}'
      - 'path: {{ node_path }}'
      - 'symlink: {{ node_path }}'
    - require:
      - archive: nvm_install

nvm_home:
  reg.present:
    - name: {{ env_registry }}
    - vname: NVM_HOME
    - vdata: {{ nvm_path }}
    - vtype: REG_SZ
    - require:
      - archive: nvm_install

# NVM_SYMLINK tells nvm-windows where to create the active node symlink/junction
nvm_symlink:
  reg.present:
    - name: {{ env_registry }}
    - vname: NVM_SYMLINK
    - vdata: {{ node_path }}
    - vtype: REG_SZ
    - require:
      - archive: nvm_install

install_default_node_version:
  cmd.run:
    - name: {{ win_cmd(nvm_bin ~ ' install ' ~ nvm_version) }}
    - shell: pwsh
    - unless: {{ nvm_bin }} list | findstr "{{ nvm_version }}"
    - require:
      - archive: nvm_install
      - file: nvm_npm_settings
      - reg: nvm_symlink

# Remove nodejs directory if it exists as real directory (not symlink)
# nvm use needs to create this as a junction/symlink
nvm_nodejs_dir_cleanup:
  cmd.run:
    - name: >
        pwsh -NoLogo -Command
        "if ((Test-Path '{{ node_path }}') -and -not ((Get-Item '{{ node_path }}').Attributes -band [IO.FileAttributes]::ReparsePoint)) { Remove-Item -Path '{{ node_path }}' -Recurse -Force }"
    - require:
      - cmd: install_default_node_version

# Activate the installed node version (creates symlink)
nvm_use_default:
  cmd.run:
    - name: {{ win_cmd(nvm_bin ~ ' use ' ~ nvm_version) }}
    - shell: pwsh
    - require:
      - cmd: nvm_nodejs_dir_cleanup
      - reg: nvm_symlink

# Install global npm packages via common orchestration
# PATH updates handled by windows.paths (avoids race conditions)
include:
  - common.nvm
  - windows.paths
