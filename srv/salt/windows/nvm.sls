# Windows Node.js version management via nvm-windows
# System-wide installation to C:\opt\nvm (consistent with Linux /opt/nvm)
# https://docs.nvm-windows.com/install/installers/
{%- from "_macros/windows.sls" import win_cmd %}

{#- NVM configuration #}
{%- set nvm_config = salt['pillar.get']('nvm', {}) %}
{%- set nvm_version = nvm_config.get('default_version', 'lts') %}

{#- Github releases #}
{%- set nvm_win_version = salt['github_release.latest']('nvm-windows/nvm') %}
{%- set assets = salt['github_release.assets']('nvm-windows/nvm', tag=nvm_win_version) %}
{%- set patterns = salt['arch_match.patterns_for'](os_family='windows') %}
{%- set matched_asset = salt['arch_match.pick'](assets, patterns, key='name') %}
{%- set installer_url = matched_asset.browser_download_url if matched_asset else none %}

{# Path configuration from pillar with defaults #}
{%- set nvm_path = salt['pillar.get']('install_paths:nvm:windows', 'C:\\opt\\nvm') %}
{%- set nvm_bin = nvm_path ~ '/nvm.exe' %}
{%- set npm_settings = nvm_path ~ '\\settings.txt' %}
{%- set node_path = nvm_path ~ '/nodejs' %}
{%- set env_registry = salt['pillar.get']('windows:env_registry', 'HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment') %}

{%- set nvm_tmp = "C:/opt/cozy/cache/nvm-setup.exe" %}

{%- from '_macros/windows.sls' import get_users_with_profiles, get_winget_system_path, get_user_winget_info, winget_batch_install with context %}

{%- set users_with_profiles = get_users_with_profiles().split(',') | reject('equalto', '') | list %}
{%- set winget_path = get_winget_system_path() | trim %}
{%- set user_info = {} %}
{%- set winget_users = [] %}

{%- for user in users_with_profiles %}
  {%- set info = get_user_winget_info(user) | load_json %}
  {%- if info %}
    {%- do user_info.update({user: info}) %}
  {%- endif %}
{%- endfor %}

nvm_npm_settings:
  file.managed:
    - name: {{ npm_settings }}
    - contents:
      - 'root: {{ nvm_path }}'
      - 'path: {{ node_path }}'
      - 'symlink: {{ node_path }}'

nvm_home:
  reg.present:
    - name: {{ env_registry }}
    - vname: NVM_HOME
    - vdata: {{ nvm_path | replace("/", "\\") }}
    - vtype: REG_SZ

# NVM_SYMLINK tells nvm-windows where to create the active node symlink/junction
nvm_symlink:
  reg.present:
    - name: {{ env_registry }}
    - vname: NVM_SYMLINK
    - vdata: {{ node_path }}
    - vtype: REG_SZ

{%- for user in users_with_profiles %}
  {%- set winget_user = user_info.get(user, {}).get("UserName", false) %}
  {%- set winget_uri = user_info.get(user, {}).get("winget_uri", false) %}
  {%- if winget_uri and winget_user and salt['file.file_exists'](winget_uri) %}
    {%- set pkgs = ['AuthorSoftware.NVMWindows'] %}
    {%- do winget_users.append(winget_user) %}
{{ winget_batch_install('nvm_install_' ~ winget_user, pkgs, winget_user, winget_uri) }}
  {%- endif %}
{%- endfor %}

install_default_node_version:
  cmd.run:
    - name: {{ win_cmd(nvm_bin ~ ' install ' ~ nvm_version) }}
    - shell: pwsh
    - unless: {{ nvm_bin }} list | findstr "{{ nvm_version }}"
    - require:
      - file: nvm_npm_settings
      - reg: nvm_symlink
{%- for winget_user in winget_users %}
  {%- if winget_user %}
      - cmd: nvm_install_{{ winget_user }}
  {%- endif %}
{%- endfor %}

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
