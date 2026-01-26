{# Windows utility macros #}

{#
  get_winget_user() - Find a managed user who has winget installed
  Returns: username string (first user with winget, or fallback to first managed user or 'admin')

  Usage:
    {% from '_macros/windows.sls' import get_winget_user with context %}
    {% set winget_user = get_winget_user() %}
#}
{%- macro get_winget_user() -%}
{#- Find first user who exists locally and has a profile (logged in at least once).
    Check service account first, then managed users. -#}
{%- set service_user = salt['pillar.get']('service_user:name', 'cozy-salt-svc') -%}
{%- set managed_users = salt['pillar.get']('managed_users', []) -%}
{%- set local_users = salt['user.list_users']() -%}
{%- set candidates = [service_user] + managed_users -%}
{%- set found_user = none -%}
{%- for user in candidates -%}
  {%- if found_user is none and user in local_users -%}
    {%- set profile_path = 'C:\\Users\\' ~ user -%}
    {%- if salt['file.directory_exists'](profile_path) -%}
      {%- set found_user = user -%}
    {%- endif -%}
  {%- endif -%}
{%- endfor -%}
{{ found_user if found_user else service_user }}
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
