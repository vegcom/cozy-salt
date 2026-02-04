{# Windows utility macros #}

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
{#- Get users with real profiles from ProfileList registry -#}
{%- set profile_cmd = 'powershell -Command "(Get-ChildItem \'HKLM:\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\ProfileList\' | % { (Get-ItemProperty $_.PSPath).ProfileImagePath } | ? { $_ -match \'C:\\\\Users\\\\\' }) -replace \'C:\\\\Users\\\\\', \'\'"' -%}
{%- set real_profiles = salt['cmd.run'](profile_cmd, shell='cmd').splitlines() -%}
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
