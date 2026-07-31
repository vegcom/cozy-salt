{%- from '_macros/windows.sls' import get_users_with_profiles, get_winget_system_path, get_user_winget_info, winget_batch_install with context %}
{%- from '_macros/packages.sls' import get_packages %}
{%- set packages = get_packages() | load_json %}
{%- set service_user = salt['pillar.get']('service_user', {}) %}
{%- set svc_name = service_user.get('name', 'cozy-salt-svc') %}
# TODO: move to grains to reduce render time
{%- set users_with_profiles = get_users_with_profiles().split(',') | reject('equalto', '') | list %}
{%- set winget_path = get_winget_system_path() | trim %}
{%- set user_info = {} %}
{%- for user in users_with_profiles %}
  {%- set info = get_user_winget_info(user) | load_json %}
  {%- if info %}
    {%- do user_info.update({user: info}) %}
  {%- endif %}
{%- endfor %}

# ============================================================================
# PowerShell Modules (from powershell_gallery) - requires pwsh installed
# ============================================================================

{%- set all_pwsh_modules = packages.windows.get('pwsh_modules', []) %}
{%- if all_pwsh_modules %}
  {%- for module in all_pwsh_modules %}
pwsh_module_{{ module | replace('.', '_') | replace('-', '_') }}:
  cmd.run:
    - shell: powershell
    - name: Install-Module -Name {{ module }} -Scope AllUsers -AllowClobber -SkipPublisherCheck -Force -Repository PSGallery
    - unless: if (!(Get-Module -ListAvailable -Name "{{ module }}")) { exit 1 }
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
    - onchanges:
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
    - unless:
      - powershell -C "choco list|select-string {{ pkg }}"
  {%- endfor %}
{%- endif %}

# ============================================================================
# WINGET INSTALLATIONS - BATCHED BY
# ============================================================================

{#- TODO: Solve similar to linux, deploy paths in full; fix/correct naming scheme  #}
{%- if packages.windows.winget.userland is defined %}
  {%- for user in users_with_profiles %}
    {%- set UserName = user_info.get(user, {}).get("UserName", false) %}
    {%- set winget_settings = user_info.get(user, {}).get("winget_settings", false) %}
    {%- if winget_settings and UserName %}
winget_config_{{ user }}:
  file.managed:
    - name: {{ winget_settings }}
    - source: salt://windows/files/LOCALAPPDATA-Packages-Microsoft.DesktopAppInstaller_8wekyb3d8bbwe-LocalState/settings.json
    - user: {{ UserName }}
    - makedirs: True
    {%- endif %}
  {%- endfor %}
{%- endif %}

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
{{ winget_batch_install('winget_batch_runtimes_' ~ category, pkgs, winget_path=winget_path, scope='machine', force=true, bg=true) }}
  {%- endfor %}
{%- endif %}

# Install Winget system packages, machine scope (batched by category)
{%- set noscope_pkgs = packages.windows.winget.get('noscope', {}).values() | list | flatten %}
{%- if packages.windows.winget.system is defined %}
  {%- for category, pkgs in packages.windows.winget.system.items() %}
    {%- set filtered_pkgs = pkgs | reject('in', noscope_pkgs) | list %}
    {%- if filtered_pkgs %}
{{ winget_batch_install('winget_batch_system_' ~ category, filtered_pkgs, winget_path=winget_path, scope='machine', force=true, bg=true) }}
    {%- endif %}
    {%- set noscope_category_pkgs = pkgs | select('in', noscope_pkgs) | list %}
    {%- if noscope_category_pkgs %}
{{ winget_batch_install('winget_batch_system_' ~ category ~ '_noscope', noscope_category_pkgs, winget_path=winget_path, scope=false, force=true, bg=true) }}
    {%- endif %}
  {%- endfor %}
{%- endif %}

# Install capability-gated system packages (host:capabilities:<name>: true)
{%- if packages.windows.winget.gated is defined %}
  {%- for cap_name, pkgs in packages.windows.winget.gated.items() %}
    {%- if salt['pillar.get']('host:capabilities:' ~ cap_name, False) %}
      {%- set filtered_pkgs = pkgs | reject('in', noscope_pkgs) | list %}
      {%- if filtered_pkgs %}
{{ winget_batch_install('winget_batch_gated_' ~ cap_name, filtered_pkgs, winget_path=winget_path, scope='machine') }}
      {%- endif %}
      {%- set noscope_gated_pkgs = pkgs | select('in', noscope_pkgs) | list %}
      {%- if noscope_gated_pkgs %}
{{ winget_batch_install('winget_batch_gated_' ~ cap_name ~ '_noscope', noscope_gated_pkgs, winget_path=winget_path, scope=false, force=true, bg=true) }}
      {%- endif %}
    {%- endif %}
  {%- endfor %}
{%- endif %}

# Install Winget userland packages (per user, batched by category)
# {{ packages.windows.winget.userland }}
{%- if packages.windows.winget.userland is defined %}
  {%- for user in users_with_profiles %}
    {%- set UserName = user_info.get(user, {}).get("UserName", false) %}
    {%- set winget_uri = user_info.get(user, {}).get("winget_uri", false) %}
    {%- if winget_uri and UserName and salt['file.file_exists'](winget_uri) %}
      {%- for category, pkgs in packages.windows.winget.userland.items() %}
{{ winget_batch_install('winget_batch_userland_' ~ UserName ~ '_' ~ category, pkgs, winget_user=UserName, winget_path=winget_uri, scope='user', force=true, bg=true) }}
      {%- endfor %}
    {%- endif %}
  {%- endfor %}
{%- endif %}
