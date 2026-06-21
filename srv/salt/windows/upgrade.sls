# Windows package upgrades
# Machine scope + per-user winget upgrades
# Called by orch.update-minion-windows

{%- from '_macros/windows.sls' import get_winget_path, get_winget_system_path, get_users_with_profiles with context %}
{%- set users_with_profiles = get_users_with_profiles().split(',') | reject('equalto', '') | list %}
{%- set winget_path = get_winget_system_path() | trim %}

# Choco upgrade
choco_upgrade:
  cmd.run:
    - name: choco upgrade all
    - onlyif: Test-Path (where.exe choco)
    - shell: powershell

# Machine scope upgrade (system-wide packages)
winget_upgrade_machine:
  cmd.run:
    - name: '{{ winget_path }} upgrade --all --accept-source-agreements --accept-package-agreements --disable-interactivity'
    # - runas: {{ svc_name }}
    - onlyif: Test-Path '{{ winget_path }}'
    - shell: powershell

# Per-user upgrades (userland packages)
{%- for user in users_with_profiles %}
{%- set user_winget = get_winget_path(user) | trim %}
winget_upgrade_{{ user | replace('.', '_') | replace('-', '_') }}:
  cmd.run:
    - name: '{{ user_winget }} upgrade --all --accept-source-agreements --accept-package-agreements --disable-interactivity'
    - runas: {{ user }}
    - shell: powershell
    - onlyif: '& ''{{ user_winget }}'' --version 2>&1 | Select-String -Quiet "v\d"'
{%- endfor %}
