# Windows package upgrades
# Machine scope + per-user winget upgrades
# Called by orch.update-minion-windows

{%- from '_macros/windows.sls' import get_winget_user, get_winget_path, get_users_with_profiles with context %}
{%- set users_with_profiles = get_users_with_profiles().split(',') | reject('equalto', '') | list %}
{%- set winget_user = get_winget_user() %}
{%- set winget_path = get_winget_path(winget_user) %}

# Machine scope upgrade (system-wide packages)
winget_upgrade_machine:
  cmd.run:
    - name: '{{ winget_path }} upgrade --all --accept-source-agreements --accept-package-agreements --disable-interactivity'
    - runas: {{ winget_user }}
    - onlyif: Test-Path '{{ winget_path }}'
    - shell: powershell

# Per-user upgrades (userland packages)
{%- for user in users_with_profiles %}
{%- set user_winget = 'C:\\Users\\' ~ user ~ '\\AppData\\Local\\Microsoft\\WindowsApps\\winget.exe' %}
winget_upgrade_{{ user | replace('.', '_') | replace('-', '_') }}:
  cmd.run:
    - name: '{{ user_winget }} upgrade --all --accept-source-agreements --accept-package-agreements --disable-interactivity'
    - runas: {{ user }}
    - shell: powershell
    - onlyif: '& ''{{ user_winget }}'' --version 2>&1 | Select-String -Quiet "v\d"'
{%- endfor %}
