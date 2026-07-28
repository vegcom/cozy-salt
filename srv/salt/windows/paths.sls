# Windows PATH management
# Consolidated here to avoid race conditions between individual state files
# Single reg.present that reads current PATH and adds all opt paths at once
# Also handles cozyusers group and WindowsApps permissions for winget access

{%- from '_macros/windows.sls' import get_users_with_profiles with context %}
{%- set winget_path = salt['pillar.get']('paths:winget', 'C:\\Program Files\\WindowsApps\\Microsoft.DesktopAppInstaller_1.27.460.0_x64__8wekyb3d8bbwe') %}
{%- set users_with_profiles = get_users_with_profiles().split(',') | reject('equalto', '') | list %}

{%- set opt_paths = [
  'C:/opt/nvm',
  'C:/opt/nvm/nodejs',
  'C:/opt/rust/bin',
  'C:/opt/miniforge3',
  'C:/opt/windhawk',
  'C:/opt/kubo',
  'C:/opt/wt',
  'C:/opt/msys',
  'C:/opt/cozy/bin',
  winget_path
] %}

# Grant cozyusers read+execute on all opt paths
# WindowsApps permissions are strict - need explicit grant for non-installing users
{%- for path in opt_paths %}
{%- set path = path | replace("/", "\\") %}
opt_path_acl_{{ loop.index }}:
  cmd.run:
    - name: |
        $InformationPreference = 'SilentlyContinue'
        $path = '{{ path }}'
        if (Test-Path $path) {
          $acl = Get-Acl $path
          $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            'cozyusers', 'ReadAndExecute', 'ContainerInherit,ObjectInherit', 'None', 'Allow'
          )
          $acl.AddAccessRule($rule)
          Set-Acl $path $acl
        }
    - output_loglevel: quiet
    - shell: pwsh
{%- endfor %}

{# Only read registry on Windows - fails on Linux master during render #}
{%- if grains['os'] == 'Windows' %}
{%- set current_path = salt['reg.read_value']('HKLM', 'SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment', 'Path').get('vdata', '') %}
{%- else %}
{%- set current_path = '' %}
{%- endif %}

# Merge paths if absent
{%- set paths = current_path.split(';') %}

{%- for p in opt_paths %}
  {%- if p not in paths %}
    {%- do paths.append(p) %}
  {%- endif %}
{%- endfor %}

{%- set merged_paths = ';'.join(paths) %}

opt_paths_update:
  reg.present:
    - name: HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment
    - vname: Path
    - vtype: REG_EXPAND_SZ
    - vdata: '{{ merged_paths }}'

paths_broadcast_env_change_system:
  cmd.run:
    - name: RUNDLL32.EXE user32.dll,SendMessageTimeout 0xffff 0x1A 0 "Environment" 2 5000
    - shell: cmd
    - onchanges:
      - reg: opt_paths_update

{%- for user in users_with_profiles %}
  {%- set username = user | replace('.' ~ grains['id'], '') %}
paths_broadcast_env_change_{{ user }}:
  cmd.run:
    - name: rundll32.exe user32.dll,UpdatePerUserSystemParameters ,1 ,True
    - shell: cmd
    - runas: {{ username }}
    - onchanges:
      - reg: opt_paths_update
{%- endfor %}
