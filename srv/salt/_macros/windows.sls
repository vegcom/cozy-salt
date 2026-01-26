{# Windows utility macros #}

{#
  get_winget_user() - Find a managed user who has winget installed
  Returns: username string (first user with winget, or fallback to first managed user or 'admin')

  Usage:
    {% from '_macros/windows.sls' import get_winget_user with context %}
    {% set winget_user = get_winget_user() %}
#}
{%- macro get_winget_user() -%}
{#- WindowsApps paths are per-user and can't be checked cross-user via file.file_exists.
    Use service account since that's who runs salt-call and has winget installed. -#}
{%- set service_user = salt['pillar.get']('service_user:name', 'cozy-salt-svc') -%}
{{ service_user }}
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
