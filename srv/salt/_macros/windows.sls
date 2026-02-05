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
