# Windows package installation
# Packages defined in provisioning/packages.sls
{%- import_yaml 'packages.sls' as packages %}
# Only install for users with real profiles (ProfileList registry check)
{%- from '_macros/windows.sls' import get_winget_user, get_winget_path, get_users_with_profiles with context %}
{%- set users_with_profiles = get_users_with_profiles().split(',') | reject('equalto', '') | list %}
{#- Find user with winget installed via macro #}
{%- set winget_user = get_winget_user() %}
{%- set winget_path = get_winget_path(winget_user) %}
{#- pwsh - from pillar #}
{%- set _pwsh_ver = salt['pillar.get']('_pinned_pwsh', salt['github_release.latest']('PowerShell/PowerShell', fallback='7.5.4')) %}
{%- set pwsh_url = 'https://github.com/PowerShell/PowerShell/releases/download/v' ~ _pwsh_ver ~ '/PowerShell-' ~ _pwsh_ver ~ '.msixbundle' %}
{%- set service_user = salt['pillar.get']('service_user', {}) %}
{%- set svc_name = service_user.get('name', 'cozy-salt-svc') %}

# PowerShell Modules (from powershell_gallery) - requires pwsh installed
{%- set all_pwsh_modules = packages.windows.get('pwsh_modules', []) %}
{%- if all_pwsh_modules %}
  {%- for module in all_pwsh_modules %}
pwsh_module_{{ module | replace('.', '_') | replace('-', '_') }}:
  cmd.run:
    - shell: pwsh
    - name: >
        Remove-Module PackageManagement,PowerShellGet -Force -ErrorAction SilentlyContinue;
        Install-Module -Name {{ module }} -Scope AllUsers -AllowClobber -SkipPublisherCheck -Force -Repository PSGallery
    - onlyif: Get-Command pwsh -ErrorAction SilentlyContinue
  {%- endfor %}
{%- endif %}

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

# Install Winget runtime packages, machine scope (run as user with winget)
{%- if packages.windows.winget.runtimes is defined %}
  {%- for category, pkgs in packages.windows.winget.runtimes.items() %}
    {%- for pkg in pkgs %}
winget_runtime_{{ pkg | replace('.', '_') | replace('-', '_') }}:
  cmd.run:
    - runas: {{ winget_user }}
    - shell: powershell
    - name: '{{ winget_path }} install --scope machine --accept-source-agreements --accept-package-agreements --disable-interactivity --exact --id {{ pkg }}'
    - unless: '{{ winget_path }} list --exact --id {{ pkg }} | Select-String -Quiet -Pattern ''{{ pkg }}'''
    - onlyif: Test-Path '{{ winget_path }}'
    - timeout: 300
    {%- endfor %}
  {%- endfor %}
{%- endif %}

# Install Winget packages by category, machine scope (run as user with winget)
# noscope list = packages that choke on --scope machine flag (360 noscope lol)
{%- set noscope_pkgs = packages.windows.winget.get('noscope', []) %}
{%- if packages.windows.winget.system is defined %}
  {%- for category, pkgs in packages.windows.winget.system.items() %}
    {%- for pkg in pkgs %}
winget_{{ pkg | replace('.', '_') | replace('-', '_') }}:
  cmd.run:
      {%- if pkg in noscope_pkgs %}
    - name: '{{ winget_path }} install --accept-source-agreements --accept-package-agreements --disable-interactivity --exact --id {{ pkg }}'
      {%- else %}
    - name: '{{ winget_path }} install --scope machine --accept-source-agreements --accept-package-agreements --disable-interactivity --exact --id {{ pkg }}'
      {%- endif %}
    - runas: {{ winget_user }}
    - shell: powershell
    - unless: '{{ winget_path }} list --exact --id {{ pkg }} | Select-String -Quiet -Pattern ''{{ pkg }}'''
    - onlyif: Test-Path '{{ winget_path }}'
    - timeout: 300
    {%- endfor %}
  {%- endfor %}
# machine scope upgrade
winget_upgrade_machine:
  cmd.run:
    - name: '{{ winget_path }} upgrade --all --accept-source-agreements --accept-package-agreements --disable-interactivity'
    - runas: {{ winget_user }}
    - onlyif: Test-Path '{{ winget_path }}'
{%- endif %}

# Installs userland packages, user scope (each user's own winget)
{%- for user in users_with_profiles %}
{%- set user_winget = 'C:\\Users\\' ~ user ~ '\\AppData\\Local\\Microsoft\\WindowsApps\\winget.exe' %}
  {%- for category, pkgs in packages.windows.winget.userland.items() %}
    {%- for pkg in pkgs %}
winget_userland_{{ user | replace('.', '_') | replace('-', '_') }}_{{ pkg | replace('.', '_') | replace('-', '_') }}:
  cmd.run:
    - name: '{{ user_winget }} install --accept-source-agreements --accept-package-agreements --disable-interactivity --exact --id {{ pkg }}'
    - runas: {{ user }}
    - shell: powershell
    - unless: '{{ user_winget }} list --exact --id {{ pkg }} | Select-String -Quiet -Pattern ''{{ pkg }}'''
    - onlyif: '& ''{{ user_winget }}'' --version 2>&1 | Select-String -Quiet "v\d"'
    - timeout: 300
    {%- endfor %}
  {%- endfor %}

# Per user winget upgrades, use cmd to upgrade pwsh
winget_upgrade_{{ user }}:
  cmd.run:
    - name: '{{ user_winget }} upgrade --all --accept-source-agreements --accept-package-agreements --disable-interactivity'
    - runas: {{ user }}
    - onlyif: '& ''{{ user_winget }}'' --version 2>&1 | Select-String -Quiet "v\d"'
{%- endfor %}
