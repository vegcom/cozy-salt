# Windows package installation
# Packages defined in provisioning/packages.sls

{% import_yaml 'packages.sls' as packages %}
{% from '_macros/windows.sls' import get_winget_user, get_winget_path, get_users_with_profiles with context %}

# ============================================================================
# BOOTSTRAP: Download and install winget (Windows Package Manager)
# ============================================================================
# NOTE: AppX/MSIX packages CANNOT be installed by SYSTEM account.
# We must install as a real user who has logged in and has winget.

{# Find user with winget installed via macro #}
{% set winget_user = get_winget_user() %}
{% set winget_path = get_winget_path(winget_user) %}

{# Winget bundle for fresh installs #}
{% set winget_url = salt['pillar.get']('bootstrap:url:winget') %}
{% set winget_bundle = 'C:\\opt\\cozy\\temp\\AppInstaller.msixbundle' %}

{# pwsh - from pillar #}
{% set pwsh_url = salt['pillar.get']('bootstrap:url:pwsh') %}
{% set service_user = salt['pillar.get']('service_user', {}) %}
{% set svc_name = service_user.get('name', 'cozy-salt-svc') %}

winget-bundle-fetch:
  file.managed:
    - name: {{ winget_bundle }}
    - source: {{ winget_url }}
    - makedirs: True
    - skip_verify: True

# Install winget as real user elevated (SYSTEM cannot install AppX packages)
# Uses Start-Process -Verb RunAs for elevation (UAC disabled via GPO)
winget-install-user:
  cmd.run:
    - name: Start-Process -FilePath powershell -ArgumentList '-Command', 'Add-AppxPackage -Path {{ winget_bundle }}' -Verb RunAs -Wait
    - shell: powershell
    - runas: {{ winget_user }}
    - require:
      - file: winget-bundle-fetch
      - user: {{ winget_user }}_user
      - user: {{ svc_name }}_service_account

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
    "exitOnRebootDetected",
    "removePackageInformationOnUninstall",
] %}

# Enable Chocolatey features
{% for feature in enable_choco_features %}
choco_feature_{{ feature }}_enabled:
  cmd.run:
    - name: choco feature enable -n={{ feature }}
    - shell: cmd
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
    - name: '{{ winget_path }} install --scope machine --accept-source-agreements --accept-package-agreements --exact --id {{ pkg }}'
    - unless: '{{ winget_path }} list --exact --id {{ pkg }} | Select-String -Quiet -Pattern ''{{ pkg }}'''
    - onlyif: Test-Path '{{ winget_path }}'
    - require:
      - cmd: winget-install-user
{% endfor %}
{% endfor %}
{% endif %}

# Install Winget packages by category, machine scope (run as user with winget)
{% if packages.windows.winget_system is defined %}
{% for category, pkgs in packages.windows.winget.system.items() %}
{% for pkg in pkgs %}
winget_{{ pkg | replace('.', '_') | replace('-', '_') }}:
  cmd.run:
    - name: '{{ winget_path }} install --scope machine --accept-source-agreements --accept-package-agreements --exact --id {{ pkg }}'
    - runas: {{ winget_user }}
    - shell: powershell
    - unless: '{{ winget_path }} list --exact --id {{ pkg }} | Select-String -Quiet -Pattern ''{{ pkg }}'''
    - onlyif: Test-Path '{{ winget_path }}'
    - require:
      - cmd: winget-install-user
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
    - name: '{{ user_winget }} install --scope user --accept-source-agreements --accept-package-agreements --exact --id {{ pkg }}'
    - runas: {{ user }}
    - shell: powershell
    - unless: '{{ user_winget }} list --exact --id {{ pkg }} | Select-String -Quiet -Pattern ''{{ pkg }}'''
    - onlyif: Test-Path '{{ user_winget }}'
    {% endfor %}
  {% endfor %}
{% endfor %}
