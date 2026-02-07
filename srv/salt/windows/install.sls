# Windows package installation
# Packages defined in provisioning/packages.sls

{% import_yaml 'packages.sls' as packages %}
{% from '_macros/windows.sls' import get_winget_user, get_winget_path, get_users_with_profiles with context %}

# ============================================================================
# WINGET: Users get winget via Microsoft Store on first login
# ============================================================================
# ProfileList-based detection ensures we only install for users who have
# actually logged in and have a working winget. No bundle install needed.

{# Find user with winget installed via macro #}
{% set winget_user = get_winget_user() %}
{% set winget_path = get_winget_path(winget_user) %}

{# pwsh - from pillar #}
{% set pwsh_url = salt['pillar.get']('bootstrap:url:pwsh') %}
{% set service_user = salt['pillar.get']('service_user', {}) %}
{% set svc_name = service_user.get('name', 'cozy-salt-svc') %}

# PowerShell Modules (from powershell_gallery) - requires pwsh installed
{% set all_pwsh_modules = packages.windows.get('pwsh_modules', []) %}
{% if all_pwsh_modules %}
{% for module in all_pwsh_modules %}
pwsh_module_{{ module | replace('.', '_') | replace('-', '_') }}:
  cmd.run:
    - shell: pwsh
    - name: >
        Install-Module -Name {{ module }} -Scope AllUsers -AllowClobber -SkipPublisherCheck -Force -Repository PSGallery
    - onlyif: Get-Command pwsh -ErrorAction SilentlyContinue
{% endfor %}
{% endif %}

chocolatey-install:
  chocolatey.bootstrapped

# TODO: pillar this
{% set enable_choco_features = [
    "allowGlobalConfirmation",
    "allowEmptyChecksumsSecure",
    "useEnhancedExitCodes",
    "failOnStandardError",
    "failOnAutoUninstaller",
    "removePackageInformationOnUninstall",
] %}

# Enable Chocolatey features
# Note: choco returns exit code 2 when config is already set (not an error)
{% for feature in enable_choco_features %}
choco_feature_{{ feature }}_enabled:
  cmd.run:
    - name: choco feature enable -n={{ feature }}
    - shell: cmd
    - success_retcodes:
      - 0
      - 2
    - require:
      - chocolatey: chocolatey-install
{% endfor %}

# Install Chocolatey packages
{% if packages.windows.choco is defined %}
{% for pkg in packages.windows.choco %}
choco_{{ pkg | replace('.', '_') | replace('-', '_') }}:
  chocolatey.installed:
    - name: {{ pkg }}
    - require:
      - chocolatey: chocolatey-install
{% endfor %}
{% endif %}

# Install Winget runtime packages, machine scope (run as user with winget)
{% if packages.windows.winget_runtimes is defined %}
{% for category, pkgs in packages.windows.winget.runtimes.items() %}
{% for pkg in pkgs %}
winget_runtime_{{ pkg | replace('.', '_') | replace('-', '_') }}:
  cmd.run:
    - runas: {{ winget_user }}
    - shell: powershell
    - name: '{{ winget_path }} install --scope machine --accept-source-agreements --accept-package-agreements --disable-interactivity --exact --id {{ pkg }}'
    - unless: '{{ winget_path }} list --exact --id {{ pkg }} | Select-String -Quiet -Pattern ''{{ pkg }}'''
    - onlyif: (Test-Path '{{ winget_path }}') -and (& '{{ winget_path }}' --version 2>$null)
    - timeout: 300
{% endfor %}
{% endfor %}
{% endif %}

# TODO: timeout=300 is a soft safety net for winget hangs (e.g. installers that
# launch the app post-install and never exit). If a legit large install needs more
# time, bump per-package via a pillar override or increase the default here.

# Install Winget packages by category, machine scope (run as user with winget)
{% if packages.windows.winget_system is defined %}
{% for category, pkgs in packages.windows.winget.system.items() %}
{% for pkg in pkgs %}
winget_{{ pkg | replace('.', '_') | replace('-', '_') }}:
  cmd.run:
    - name: '{{ winget_path }} install --scope machine --accept-source-agreements --accept-package-agreements --disable-interactivity --exact --id {{ pkg }}'
    - runas: {{ winget_user }}
    - shell: powershell
    - unless: '{{ winget_path }} list --exact --id {{ pkg }} | Select-String -Quiet -Pattern ''{{ pkg }}'''
    - onlyif: (Test-Path '{{ winget_path }}') -and (& '{{ winget_path }}' --version 2>$null)
    - timeout: 300
{% endfor %}
{% endfor %}
{% endif %}

# Installs userland packages, user scope (each user's own winget)
# Only install for users with real profiles (ProfileList registry check)
{% set users_with_profiles = get_users_with_profiles().split(',') | reject('equalto', '') | list %}
{% for user in users_with_profiles %}
{% set user_winget = 'C:\\Users\\' ~ user ~ '\\AppData\\Local\\Microsoft\\WindowsApps\\winget.exe' %}
  {% for category, pkgs in packages.windows.winget.userland.items() %}
    {% for pkg in pkgs %}
winget_userland_{{ user | replace('.', '_') | replace('-', '_') }}_{{ pkg | replace('.', '_') | replace('-', '_') }}:
  cmd.run:
    - name: '{{ user_winget }} install --accept-source-agreements --accept-package-agreements --disable-interactivity --exact --id {{ pkg }}'
    - runas: {{ user }}
    - shell: powershell
    - unless: '{{ user_winget }} list --exact --id {{ pkg }} | Select-String -Quiet -Pattern ''{{ pkg }}'''
    - onlyif: (Test-Path '{{ user_winget }}') -and (& '{{ user_winget }}' --version 2>$null)
    - timeout: 300
    {% endfor %}
  {% endfor %}
{% endfor %}
