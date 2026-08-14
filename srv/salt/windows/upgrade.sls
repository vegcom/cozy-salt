# Windows package upgrades
# Machine scope + per-user winget upgrades
# Called by orch.update-minion-windows

{%- from '_macros/windows.sls' import get_winget_path, get_winget_system_path, get_users_with_profiles with context %}
{%- set users_with_profiles = get_users_with_profiles().split(',') | reject('equalto', '') | list %}
{%- set winget_path = get_winget_system_path() | trim %}

# pwsh modules
pwsh_module_upgrade:
  cmd.run:
    - name: |-
        (Get-InstalledModule).Name|ForEach { Update-Module -Scope AllUsers -AllowPrerelease -Force -Name $_ }
    - onlyif: Test-Path (where.exe pwsh)
    - shell: pwsh

# Choco upgrade
choco_upgrade:
  cmd.run:
    - name: choco upgrade all
    - onlyif: Test-Path (where.exe choco)
    - shell: powershell

# Machine scope upgrade (system-wide packages)
winget_upgrade_machine:
  cmd.run:
    - name: |-
        &"{{ winget_path }}" upgrade --all --scope machine --accept-source-agreements --accept-package-agreements --disable-interactivity
    - onlyif: Test-Path '{{ winget_path }}'
    - shell: powershell

# Per-user upgrades (userland packages)
{%- for user in users_with_profiles | unique | sort %}
{%- set user_winget = get_winget_path(user) | trim %}
{%- set base_user = user | replace('.' ~ grains['id'], '') %}
winget_upgrade_{{ user | replace('.', '_') | replace('-', '_') }}:
  cmd.run:
    - name: |-
        &"{{ user_winget }}" upgrade --all --scope user --accept-source-agreements --accept-package-agreements --disable-interactivity
    - runas: {{ base_user }}
    - shell: powershell
    - onlyif: '& ''{{ user_winget }}'' --version 2>&1 | Select-String -Quiet "v\d"'
{%- endfor %}
