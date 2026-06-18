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
{%- set managed_users = salt['pillar.get']('managed_users', [], merge=True) -%}
{%- set real_profiles = _get_real_profiles().splitlines() -%}
{%- set valid_users = [] -%}
{%- for user in managed_users -%}
  {%- for profile in real_profiles -%}
    {%- if profile == user or profile.startswith(user ~ '.') -%}
      {%- do valid_users.append(profile) -%}
    {%- endif -%}
  {%- endfor -%}
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
{%- set managed_users = salt['pillar.get']('managed_users', [], merge=True) -%}
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
C:\Users\{{ user }}\AppData\Local\Microsoft\WindowsApps\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\winget.exe
{%- endmacro -%}


{#-
Macro: win_cmd
Purpose: Wrap Windows cmd.run with standard environment variables
This ensures consistent tool paths (NVM_HOME, NVM_SYMLINK, CONDA_HOME) across all Windows states

Parameters:
  command: The command to execute (string)
  extra_env: Optional dict of additional environment variables to set

Default environment variables (from pillar or defaults):
  - NVM_HOME: C:\opt\nvm (or from pillar.install_paths.nvm.windows)
  - NVM_SYMLINK: C:\opt\nvm\nodejs (or from pillar.install_paths.nvm.windows + \nodejs)
  - CONDA_HOME: C:\opt\miniforge3 (or from pillar.install_paths.miniforge.windows)

Example usage:
  {%- from "macros/windows.sls" import win_cmd %}

  install_nvm:
    cmd.run:
      - name: {{ win_cmd('nvm install lts') }}
      - shell: powershell

Example with extra environment variables:
  {%- from "macros/windows.sls" import win_cmd %}

  build_project:
    cmd.run:
      - name: {{ win_cmd('build.exe', {'RUST_BACKTRACE': '1'}) }}
      - shell: powershell
-#}

{%- macro win_cmd(command, extra_env=None) -%}
  {%- set nvm_path = salt['pillar.get']('install_paths:nvm:windows', 'C:\\opt\\nvm') -%}
  {%- set node_path = nvm_path ~ '\\nodejs' -%}
  {%- set miniforge_path = salt['pillar.get']('install_paths:miniforge:windows', 'C:\\opt\\miniforge3') -%}

  {%- set env_vars = {
    'NVM_HOME': nvm_path,
    'NVM_SYMLINK': node_path,
    'CONDA_HOME': miniforge_path
  } -%}

  {%- if extra_env -%}
    {%- do env_vars.update(extra_env) -%}
  {%- endif -%}

  {%- set env_lines = [] -%}
  {%- for key, value in env_vars.items() -%}
    {%- do env_lines.append('$env:' ~ key ~ ' = "' ~ value ~ '"') -%}
  {%- endfor -%}

{{ env_lines | join('; ') }}; {{ command }}
{%- endmacro -%}

{#-
Macro: winget_batch_install
Purpose: Generate a batched winget install state for multiple packages in a category

Parameters:
  state_name: Unique state ID (e.g., 'winget_batch_runtimes_vcredist')
  packages: List of package IDs to install
  winget_user: User to run winget as
  winget_path: Full path to winget.exe
  scope: Install scope ('machine' or 'user', default: 'machine')
  skip_dependencies: Skip processing dependencies (default: false)

Returns:
  YAML state block that installs all packages in one call

Features:
  - Batches multiple packages into single winget install call
  - Passes --exact --accept-source-agreements --accept-package-agreements
  - Uses --no-upgrade to skip upgrades (winget returns true if already installed)
  - Reduces state count: ~50 individual installs → ~15 batched installs

Example usage:
  {%- from '_macros/windows.sls' import winget_batch_install %}
  {%- set pkgs = ['Microsoft.VisualStudioCode', 'Microsoft.VisualStudioCode.CLI'] %}
  {{ winget_batch_install('winget_batch_editor', pkgs, winget_user, winget_path) }}

Output generates:
  winget_batch_editor:
    cmd.run:
      - name: C:\...\winget.exe install --exact --scope machine ... pkg1 pkg2 pkg3
      - runas: <user>
      - shell: powershell
      - timeout: 600
-#}
{%- macro winget_batch_install(state_name, packages, winget_user=false, winget_path=false, scope=false, skip_deps=false, prerelease=false, shell="powershell", force=false, upgrade=true) -%}
{%- if packages | length > 0 -%}
{%- if not winget_path %}
  {%- set winget_path =  salt['cmd.run']('@((Get-Item("C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller*\winget.exe")).VersionInfo.FileName)[-1] 2>$null', shell='pwsh') %}
{%- endif %}
{{ state_name }}:
  cmd.run:
    - name: '&"{{ winget_path }}" install --exact {% if scope %} --scope {{ scope }}{% endif %} {% if prerelease %}--include-prerelease{% endif %} {% if not upgrade %}--no-upgrade{% endif %} --accept-source-agreements --accept-package-agreements --disable-interactivity {% if skip_deps %}--skip-dependencies{% endif %} {% if force %}--force{% endif %} {{ packages | join(" ") }}'
    {% if winget_user %}- runas: {{ winget_user }}{% endif %}
    {% if shell %}- shell: {{ shell }}{% endif %}
    - timeout: 600
{%- endif -%}
{%- endmacro -%}
