# Windows package installation
# Packages defined in provisioning/packages.sls
{%- import_yaml 'packages.sls' as packages %}
# Only install for users with real profiles (ProfileList registry check)
{%- from '_macros/windows.sls' import get_winget_user, get_winget_path, get_users_with_profiles, winget_batch_install with context %}
{%- set users_with_profiles = get_users_with_profiles().split(',') | reject('equalto', '') | list %}
{#- Service user performs scope=machine always #}
{%- set service_user = salt['pillar.get']('service_user', {}) %}
{%- set svc_name = service_user.get('name', 'cozy-salt-svc') %}
{#- Find user with winget installed via macro and check; solves for highest version and duplicates #}
{%- set winget_path = salt['cmd.run']('@((Get-Item("C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller*\winget.exe")).VersionInfo.FileName)[-1] 2>$null', shell='powershell') %}
{#- gate on file present #}
{%- if salt['file.file_exists'](winget_path) %}
{#- pwsh - from pillar #}
{%- set _pwsh_ver = salt['pillar.get']('_pinned_pwsh', salt['github_release.latest']('PowerShell/PowerShell', fallback='7.5.4')) %}
{%- set pwsh_url = 'https://github.com/PowerShell/PowerShell/releases/download/v' ~ _pwsh_ver ~ '/PowerShell-' ~ _pwsh_ver ~ '.msixbundle' %}

# ============================================================================
# PowerShell Modules (from powershell_gallery) - requires pwsh installed
# ============================================================================

{%- set all_pwsh_modules = packages.windows.get('pwsh_modules', []) %}
{%- if all_pwsh_modules %}
  {%- for module in all_pwsh_modules %}
pwsh_module_{{ module | replace('.', '_') | replace('-', '_') }}:
  cmd.run:
    - shell: powershell
    - name: >
        # Remove-Module PackageManagement,PowerShellGet -Force -ErrorAction SilentlyContinue|Out-Null;
        Install-Module -Name {{ module }} -Scope AllUsers -AllowClobber -SkipPublisherCheck -Force -Repository PSGallery 2>$null
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
{{ winget_batch_install('winget_batch_runtimes_' ~ category, pkgs, scope='machine') }}
  {%- endfor %}
{%- endif %}
# Install Winget system packages, machine scope (batched by category)
{%- set noscope_pkgs = packages.windows.winget.get('noscope', []) %}
{%- if packages.windows.winget.system is defined %}
  {%- for category, pkgs in packages.windows.winget.system.items() %}
    {%- set filtered_pkgs = pkgs | reject('in', noscope_pkgs) | list %}
    {%- if filtered_pkgs %}
{{ winget_batch_install('winget_batch_system_' ~ category, filtered_pkgs, scope='machine') }}
    {%- endif %}
    {%- set noscope_category_pkgs = pkgs | select('in', noscope_pkgs) | list %}
    {%- if noscope_category_pkgs %}
{{ winget_batch_install('winget_batch_system_' ~ category ~ '_noscope', noscope_category_pkgs, scope=false) }}
    {%- endif %}
  {%- endfor %}
{%- endif %}
# Install Winget userland packages (per user, batched by category)
{%- if packages.windows.winget.userland is defined %}
  {%- for user in users_with_profiles %}
    {#- TODO: move this evaluation up, likely create a dict for user_name user_host user_basedir user_winget so it doesn't run per category #}
    {%- set user_name = user.split(".")[0] %}
    {%- set user_host = user.split(".")[1] %}
    {%- set user_basedir = salt['cmd.run']('@((Get-Item $env:UserProfile).BaseName)[-1] 2>$null', runas=user_name) %}
    {%- set user_winget = 'C:\\Users\\' ~ user_basedir ~ '\\AppData\\Local\\Microsoft\\WindowsApps\\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\\winget.exe' %}
    {%- if salt['file.file_exists'](user_winget) %}
      {%- for category, pkgs in packages.windows.winget.userland.items() %}
{{ winget_batch_install('winget_batch_userland_' ~ user_name | replace('.', '_') | replace('-', '_') ~ '_' ~ category, pkgs, winget_user=user_name, winget_path=user_winget, scope='user') }}
      {%- endfor %}
      {%- endif %}
    {%- endfor %}
{%- endif %}

{%- endif %}
