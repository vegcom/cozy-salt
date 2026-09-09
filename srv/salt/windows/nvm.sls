# Windows Node.js version management via nvm-windows
# System-wide installation to C:\opt\nvm (consistent with Linux /opt/nvm)
{%- from "_macros/windows.sls" import win_cmd %}

{#- NVM configuration #}
{%- set nvm_config = salt['pillar.get']('nvm', {}) %}
{%- set nvm_version = nvm_config.get('default_version', 'lts') %}

{#- Github releases #}
{%- set nvm_win_version = salt['github_release.latest']('nvm-windows/nvm') %}
{%- set assets = salt['github_release.assets']('nvm-windows/nvm', tag=nvm_win_version) %}
{%- set patterns = salt['arch_match.patterns_for'](os_family='windows') %}
{%- set matched_asset = salt['arch_match.pick'](assets, patterns, key='name') %}│
{%- set installer_url = matched_asset.browser_download_url if matched_asset else none %}

{# Path configuration from pillar with defaults #}
{%- set nvm_path = salt['pillar.get']('install_paths:nvm:windows', 'C:\\opt\\nvm') %}
{%- set nvm_bin = nvm_path ~ '/nvm.exe' %}
{%- set npm_settings = nvm_path ~ '\\settings.txt' %}
{%- set node_path = nvm_path ~ '/nodejs' %}
{%- set env_registry = salt['pillar.get']('windows:env_registry', 'HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment') %}

{%- set nvm_tmp = "C:/opt/cozy/cache/nvm-setup.exe" %}

nvm_installer:
  file.managed:
    - name: {{ nvm_tmp }}
    - source: {{ installer_url }}
    - skip_verify: True
    - mkdirs: True

# DEBUG: nvm_win_version {{ nvm_win_version }}
# DEBUG: assets {{ assets }}
# DEBUG: patterns {{ patterns }}
# DEBUG: installer_url {{ installer_url }}

nvm_install:
  cmd.run:
    - name: >
        & "{{ nvm_tmp }}" /SILENT /DIR={{ nvm_path | replace("/", "\\") }}
    - require:
      - file: nvm_installer

nvm_npm_settings:
  file.managed:
    - name: {{ npm_settings }}
    - contents:
      - 'root: {{ nvm_path }}'
      - 'path: {{ node_path }}'
      - 'symlink: {{ node_path }}'
    - require:
      - cmd: nvm_install

nvm_home:
  reg.present:
    - name: {{ env_registry }}
    - vname: NVM_HOME
    - vdata: {{ nvm_path | replace("/", "\\") }}
    - vtype: REG_SZ
    - require:
      - cmd: nvm_install

# NVM_SYMLINK tells nvm-windows where to create the active node symlink/junction
nvm_symlink:
  reg.present:
    - name: {{ env_registry }}
    - vname: NVM_SYMLINK
    - vdata: {{ node_path }}
    - vtype: REG_SZ
    - require:
      - cmd: nvm_install

install_default_node_version:
  cmd.run:
    - name: {{ win_cmd(nvm_bin ~ ' install ' ~ nvm_version) }}
    - shell: pwsh
    - unless: {{ nvm_bin }} list | findstr "{{ nvm_version }}"
    - require:
      - cmd: nvm_install
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
