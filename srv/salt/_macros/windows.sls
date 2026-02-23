{# Windows utility macros #}

{#
  _get_real_profiles() - Internal helper to get users with ProfileList entries
  Returns: newline-separated list of usernames with real Windows profiles
#}
{%- macro _get_real_profiles() -%}
{%- set profile_cmd = 'powershell -Command "Get-ChildItem \'HKLM:\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\ProfileList\' | % { (Get-ItemProperty $_.PSPath).ProfileImagePath } | ? { $_ -like \'C:\\Users\\*\' } | % { Split-Path $_ -Leaf }"' -%}
{{ salt['cmd.run'](profile_cmd, shell='cmd') }}
{%- endmacro -%}

{#
  get_users_with_profiles() - Get managed_users that have real Windows profiles
  Returns: comma-separated string of usernames (use .split(',') to iterate)

  Uses ProfileList registry to detect users who have actually logged in,
  not just users with a home directory created.

  Usage:
    {% from '_macros/windows.sls' import get_users_with_profiles with context %}
    {% for user in get_users_with_profiles().split(',') %}
    ...
    {% endfor %}
#}
{%- macro get_users_with_profiles() -%}
{%- set managed_users = salt['pillar.get']('managed_users', []) -%}
{%- set real_profiles = _get_real_profiles().splitlines() -%}
{%- set valid_users = [] -%}
{%- for user in managed_users -%}
  {%- if user in real_profiles -%}
    {%- do valid_users.append(user) -%}
  {%- endif -%}
{%- endfor -%}
{{ valid_users | join(',') }}
{%- endmacro -%}

{#
  get_winget_user() - Find a managed user who has a real Windows profile
  Returns: username string (first managed user with real profile, or fallback)

  Uses ProfileList registry to detect users who have actually logged in,
  not just users with a home directory created.

  Usage:
    {% from '_macros/windows.sls' import get_winget_user with context %}
    {% set winget_user = get_winget_user() %}
#}
{%- macro get_winget_user() -%}
{%- set managed_users = salt['pillar.get']('managed_users', []) -%}
{%- set service_user = salt['pillar.get']('service_user:name', 'cozy-salt-svc') -%}
{%- set real_profiles = _get_real_profiles().splitlines() -%}
{#- Prefer managed_users with real profiles over service account -#}
{%- set candidates = managed_users + [service_user] -%}
{%- set found_user = none -%}
{%- for user in candidates -%}
  {%- if found_user is none and user in real_profiles -%}
    {%- set found_user = user -%}
  {%- endif -%}
{%- endfor -%}
{{ found_user if found_user else managed_users[0] if managed_users else 'admin' }}
{%- endmacro -%}

{#
  get_winget_path(user) - Get winget path for a specific user
  Returns: Full path to user's winget.exe

  Usage:
    {% from '_macros/windows.sls' import get_winget_path %}
    {% set winget = get_winget_path('admin') %}
#}
{%- macro get_winget_path(user) -%}
C:\Users\{{ user }}\AppData\Local\Microsoft\WindowsApps\winget.exe
{%- endmacro -%}


{#-
Macro: win_cmd
Purpose: Wrap Windows cmd.run with standard environment variables
This ensures consistent tool paths (NVM_HOME, NVM_SYMLINK, CONDA_HOME) across all Windows states

Parameters:
  command: The command to execute (string)
  extra_env: Optional dict of additional environment variables to set

Default environment variables (from pillar or defaults):
  - NVM_HOME: C:\opt\nvm (or from pillar.install_paths.nvm.windows)
  - NVM_SYMLINK: C:\opt\nvm\nodejs (or from pillar.install_paths.nvm.windows + \nodejs)
  - CONDA_HOME: C:\opt\miniforge3 (or from pillar.install_paths.miniforge.windows)

Example usage:
  {%- from "macros/windows.sls" import win_cmd %}

  install_nvm:
    cmd.run:
      - name: {{ win_cmd('nvm install lts') }}
      - shell: pwsh

Example with extra environment variables:
  {%- from "macros/windows.sls" import win_cmd %}

  build_project:
    cmd.run:
      - name: {{ win_cmd('build.exe', {'RUST_BACKTRACE': '1'}) }}
      - shell: pwsh
-#}

{%- macro win_cmd(command, extra_env=None) -%}
  {%- set nvm_path = salt['pillar.get']('install_paths:nvm:windows', 'C:\\opt\\nvm') -%}
  {%- set node_path = nvm_path ~ '\\nodejs' -%}
  {%- set miniforge_path = salt['pillar.get']('install_paths:miniforge:windows', 'C:\\opt\\miniforge3') -%}

  {%- set env_vars = {
    'NVM_HOME': nvm_path,
    'NVM_SYMLINK': node_path,
    'CONDA_HOME': miniforge_path
  } -%}

  {%- if extra_env -%}
    {%- do env_vars.update(extra_env) -%}
  {%- endif -%}

  {%- set env_lines = [] -%}
  {%- for key, value in env_vars.items() -%}
    {%- do env_lines.append('$env:' ~ key ~ ' = "' ~ value ~ '"') -%}
  {%- endfor -%}

{{ env_lines | join('; ') }}; {{ command }}
{%- endmacro -%}
