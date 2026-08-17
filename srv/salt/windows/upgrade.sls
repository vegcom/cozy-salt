# Windows package upgrades
# Machine scope + per-user winget upgrades
# Called by orch.update-minion-windows

{%- from '_macros/windows.sls' import get_winget_system_path, get_users_with_profiles with context %}
{%- set winget_path = get_winget_system_path() | trim %}

# pwsh modules
pwsh_module_upgrade:
  cmd.run:
    - name: |-
        pwsh -Command '(Get-InstalledModule).Name|ForEach { Update-Module -Scope AllUsers -AllowPrerelease -Force -Name $_ }'
    - shell: powershell

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
