{# Windows utility macros #}

{#
  get_winget_user() - Find a managed user who has winget installed
  Returns: username string (first user with winget, or fallback to first managed user or 'admin')

  Usage:
    {% from '_macros/windows.sls' import get_winget_user with context %}
    {% set winget_user = get_winget_user() %}
#}
{%- macro get_winget_user() -%}
{%- set managed_users = salt['pillar.get']('managed_users', []) -%}
{%- set service_user = salt['pillar.get']('service_user:name', 'cozy-salt-svc') -%}
{%- set check_users = [service_user] + managed_users -%}
{%- set found_user = none -%}
{%- for user in check_users -%}
  {%- set user_winget = 'C:\\Users\\' ~ user ~ '\\AppData\\Local\\Microsoft\\WindowsApps\\winget.exe' -%}
  {%- if found_user is none and salt['file.file_exists'](user_winget) -%}
    {%- set found_user = user -%}
  {%- endif -%}
{%- endfor -%}
{{ found_user if found_user else (managed_users[0] if managed_users else 'admin') }}
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
