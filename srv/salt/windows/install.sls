{%- import_yaml 'packages.sls' as packages %}
{%- from '_macros/windows.sls' import get_winget_user, get_winget_path, get_users_with_profiles, winget_batch_install with context %}
{#- pwsh - from pillar #}
{%- set _pwsh_ver = salt['pillar.get']('_pinned_pwsh', salt['github_release.latest']('PowerShell/PowerShell', fallback='7.5.4')) %}
{%- set pwsh_url = 'https://github.com/PowerShell/PowerShell/releases/download/v' ~ _pwsh_ver ~ '/PowerShell-' ~ _pwsh_ver ~ '.msixbundle' %}
{%- set pwsh_path = "C:/Program Files/PowerShell/7/pwsh.exe" %}
{#- Service user performs scope=machine always #}
{%- set service_user = salt['pillar.get']('service_user', {}) %}
{%- set svc_name = service_user.get('name', 'cozy-salt-svc') %}
{#- Only install for users with real profiles (ProfileList registry check) #}
{%- set users_with_profiles = get_users_with_profiles().split(',') | reject('equalto', '') | list %}
{%- set user_info = {} %}
{%- for user in users_with_profiles %}
  {%- set _user = user.split(".")[0] %}
  {%- set UserName = salt['cmd.run']('[Environment]::("UserName")', shell="powershell", runas=_user) or false %}
  {%- set UserProfile = salt['cmd.run']('[Environment]::GetFolderPath("UserProfile").Replace("\\", "/")', shell="powershell", runas=_user) or false %}
  {%- set LocalAppData = salt['cmd.run']('[Environment]::GetFolderPath("LocalApplicationData").Replace("\\", "/")', shell="powershell", runas=_user) or false %}
  {%- set _winget_uri_ = salt['cmd.run']('(Join-Path ([Environment]::GetFolderPath("LocalApplicationData")) "Microsoft/WindowsApps/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe/winget.exe").Replace("\\", "/")', shell="powershell", runas=_user) or false %}
  {%- if salt['cmd.run']("Test-Path " ~ _winget_uri_ ~ " 2>$null", shell="powershell") %}
    {%- set _ = user_info.update({user: {"UserName": UserName ,"UserProfile": UserProfile, "LocalAppData": LocalAppData, "_winget_uri_": _winget_uri_ }}) %}
  {%- endif %}
{%- endfor %}

{#- Find user with winget installed via macro and check; solves for highest version and duplicates #}
{%- set winget_path = salt['cmd.run']('@((Get-Item("C:/Program Files/WindowsApps/Microsoft.DesktopAppInstaller*/winget.exe")).VersionInfo.FileName)[-1].Replace("\\\", "/") 2>$null', shell='powershell') %}


# ============================================================================
# PowerShell Modules (from powershell_gallery) - requires pwsh installed
# ============================================================================

{%- set all_pwsh_modules = packages.windows.get('pwsh_modules', []) %}
{%- if all_pwsh_modules %}
  {%- for module in all_pwsh_modules %}
pwsh_module_{{ module | replace('.', '_') | replace('-', '_') }}:
  cmd.run:
    - shell: powershell
    {#- FIXME: edge cases may require `Remove-Module PackageManagement,PowerShellGet -Force -ErrorAction SilentlyContinue|Out-Null` #}
    - name: Install-Module -Name {{ module }} -Scope AllUsers -AllowClobber -SkipPublisherCheck -Force -Repository PSGallery 2>$null
    - onlyif: Get-Command pwsh -ErrorAction SilentlyContinue 2>$null|Out-Null
  {%- endfor %}
{%- endif %}

# ============================================================================
# CHOCO INSTALLATIONS
# ============================================================================

chocolatey-install:
  chocolatey.bootstrapped

# Enable Chocolatey features
{%- set choco_feature_list = pillar.get('choco_features', []) %}
{%- if choco_feature_list %}
  {%- for feature in choco_feature_list %}
choco_feature_{{ feature }}_enabled:
  cmd.run:
    - name: choco feature enable -n={{ feature }}
    - shell: cmd
    - success_retcodes:
      - 0
      - 2
    - require:
      - chocolatey: chocolatey-install
  {%- endfor %}
{%- endif %}

# Install Chocolatey packages
{%- if packages.windows.choco is defined %}
  {%- for pkg in packages.windows.choco %}
choco_{{ pkg | replace('.', '_') | replace('-', '_') }}:
  chocolatey.installed:
    - name: {{ pkg }}
    - require:
      - chocolatey: chocolatey-install
  {%- endfor %}
{%- endif %}

# ============================================================================
# WINGET INSTALLATIONS - BATCHED BY
# ============================================================================

# Winget bootstrap/repair
winget_bootstrap:
  cmd.run:
    - name: Repair-WinGetPackageManager -AllUsers -IncludePrerelease -Force -Verbose
    - shell: powershell
    - onlyif: winget settings export --disable-interactivity | Out-Null

# Winget features
winget_features_enable:
  cmd.run:
    - shell: powershell
    - name: winget configure --enable

# Install Winget runtime packages, machine scope (batched by sub-category)
{%- if packages.windows.winget.runtimes is defined %}
  {%- for category, pkgs in packages.windows.winget.runtimes.items() %}
{{ winget_batch_install('winget_batch_runtimes_' ~ category, pkgs, winget_path=winget_path, scope='machine') }}
  {%- endfor %}
{%- endif %}

# Install Winget system packages, machine scope (batched by category)
{%- set noscope_pkgs = packages.windows.winget.get('noscope', []) %}
{%- if packages.windows.winget.system is defined %}
  {%- for category, pkgs in packages.windows.winget.system.items() %}
    {%- set filtered_pkgs = pkgs | reject('in', noscope_pkgs) | list %}
    {%- if filtered_pkgs %}
{{ winget_batch_install('winget_batch_system_' ~ category, filtered_pkgs, winget_path=winget_path, scope='machine') }}
    {%- endif %}
    {%- set noscope_category_pkgs = pkgs | select('in', noscope_pkgs) | list %}
    {%- if noscope_category_pkgs %}
{{ winget_batch_install('winget_batch_system_' ~ category ~ '_noscope', noscope_category_pkgs, winget_path=winget_path, scope=false) }}
    {%- endif %}
  {%- endfor %}
{%- endif %}

# Install Winget userland packages (per user, batched by category)
{%- if packages.windows.winget.userland is defined %}
# {{ users_with_profiles }}
  {%- for user in users_with_profiles %}
    {%- set UserName = user_info.get(user, {}).get("UserName", false) %}
    {%- set _winget_uri_ = user_info.get(user, {}).get("_winget_uri_", false) %}
    {%- if _winget_uri_ and UserName %}
      {%- for category, pkgs in packages.windows.winget.userland.items() %}
{{ winget_batch_install('winget_batch_userland_' ~ UserName ~ '_' ~ category, pkgs, winget_user=UserName, winget_path=_winget_uri_, scope='user') }}
      {%- endfor %}
    {%- endif %}
  {%- endfor %}
{%- endif %}
