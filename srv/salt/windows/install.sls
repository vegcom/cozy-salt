{%- from '_macros/windows.sls' import get_users_with_profiles, get_winget_system_path, get_user_winget_info, winget_batch_install with context %}
{%- from '_macros/packages.sls' import get_packages %}
{%- from '_macros/winget.sls' import classify_winget_scopes with context %}
{%- set packages = get_packages() | load_json %}

{%- set service_user = salt['pillar.get']('service_user', {}) %}

{%- set winget_force = salt['pillar.get']('windows:winget:force', False) %}
{%- set winget_bg = salt['pillar.get']('windows:winget:bg', False) %}
{%- set winget_prerelease = salt['pillar.get']('windows:winget:prerelease', False) %}

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
    - name: |-
        powershell -Command "Import-Module PowerShellGet ; Install-Module -Name {{ module }} -Scope AllUsers -AllowClobber -SkipPublisherCheck -Force -Repository PSGallery"
    - unless: powershell -Command 'if (!(Get-Module -ListAvailable -Name "{{ module }}")) { exit 1 }'
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
      - powershell -C "choco list|Select-String {{ pkg }}"
  {%- endfor %}
{%- endif %}

# ============================================================================
# WINGET INSTALLATIONS - BATCHED BY CATEGORY, ROUTED BY MANIFEST SCOPE
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

{#- Every non-gated winget category lives flat under windows.winget now -
   the manifest server tells us per-package whether it's machine-scoped,
   user-scoped only, or scopeless, so no more hand-maintained noscope list. #}
{%- set _system_categories = {} %}
{%- for _cat, _pkgs in packages.windows.winget.items() %}
  {%- if _cat not in ['gated'] %}
    {%- do _system_categories.update({_cat: _pkgs}) %}
  {%- endif %}
{%- endfor %}

{%- set _all_winget_ids = namespace(ids=[]) %}
{%- for _pkgs in _system_categories.values() %}
  {%- do _all_winget_ids.ids.extend(_pkgs) %}
{%- endfor %}
{%- for _pkgs in packages.windows.winget.get('gated', {}).values() %}
  {%- do _all_winget_ids.ids.extend(_pkgs) %}
{%- endfor %}
{%- set scopes = classify_winget_scopes(_all_winget_ids.ids) | load_json %}

{#- winget_config_{user}: needed before any per-user (non-machine-scope) install #}
{%- if scopes.user or scopes.none %}
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

# Install Winget packages (batched by category, routed to machine/user/none)
{%- for category, pkgs in _system_categories.items() %}
  {%- set machine_pkgs = pkgs | select('in', scopes.machine) | list %}
  {%- set user_pkgs = pkgs | select('in', scopes.user) | list %}
  {%- set none_pkgs = pkgs | select('in', scopes.none) | list %}
  {%- if machine_pkgs %}
{{ winget_batch_install('winget_batch_machine_' ~ category, machine_pkgs, winget_path=winget_path, scope='machine', force=winget_force, bg=winget_bg) }}
  {%- endif %}
  {%- if user_pkgs or none_pkgs %}
    {%- for user in users_with_profiles %}
      {%- set UserName = user_info.get(user, {}).get("UserName", false) %}
      {%- set winget_uri = user_info.get(user, {}).get("winget_uri", false) %}
      {%- if winget_uri and UserName and salt['file.file_exists'](winget_uri) %}
        {%- if user_pkgs %}
{{ winget_batch_install('winget_batch_user_' ~ UserName ~ '_' ~ category, user_pkgs, winget_user=UserName, winget_path=winget_uri, scope='user', force=winget_force, bg=winget_bg) }}
        {%- endif %}
        {%- if none_pkgs %}
{{ winget_batch_install('winget_batch_none_' ~ UserName ~ '_' ~ category, none_pkgs, winget_user=UserName, winget_path=winget_uri, scope=false, force=winget_force, bg=winget_bg) }}
        {%- endif %}
      {%- endif %}
    {%- endfor %}
  {%- endif %}
{%- endfor %}

# Install capability-gated packages (host:capabilities:$name: true)
{%- if packages.windows.winget.gated is defined %}
  {%- for cap_name, pkgs in packages.windows.winget.gated.items() %}
    {%- if salt['pillar.get']('host:capabilities:' ~ cap_name, False) %}
      {%- set machine_pkgs = pkgs | select('in', scopes.machine) | list %}
      {%- if machine_pkgs %}
{{ winget_batch_install('winget_batch_gated_' ~ cap_name, machine_pkgs, winget_path=winget_path, scope='machine', force=winget_force, bg=winget_bg) }}
      {%- endif %}
      {%- set user_pkgs = pkgs | select('in', scopes.user) | list %}
      {%- set none_pkgs = pkgs | select('in', scopes.none) | list %}
      {%- if user_pkgs or none_pkgs %}
        {%- for user in users_with_profiles %}
          {%- set UserName = user_info.get(user, {}).get("UserName", false) %}
          {%- set winget_uri = user_info.get(user, {}).get("winget_uri", false) %}
          {%- if winget_uri and UserName and salt['file.file_exists'](winget_uri) %}
            {%- if user_pkgs %}
{{ winget_batch_install('winget_batch_gated_' ~ cap_name ~ '_' ~ UserName ~ '_user', user_pkgs, winget_user=UserName, winget_path=winget_uri, scope='user', force=winget_force, bg=winget_bg) }}
            {%- endif %}
            {%- if none_pkgs %}
{{ winget_batch_install('winget_batch_gated_' ~ cap_name ~ '_' ~ UserName ~ '_none', none_pkgs, winget_user=UserName, winget_path=winget_uri, scope=false, force=winget_force, bg=winget_bg) }}
            {%- endif %}
          {%- endif %}
        {%- endfor %}
      {%- endif %}
    {%- endif %}
  {%- endfor %}
{%- endif %}
