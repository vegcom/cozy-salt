# Windows package installation
# Packages defined in provisioning/packages.sls

{% import_yaml 'packages.sls' as packages %}

# ============================================================================
# BOOTSTRAP: Download and install winget (Windows Package Manager)
# ============================================================================
# NOTE: AppX/MSIX packages CANNOT be installed by SYSTEM account.
# We must install as a real user. Once installed for one user, winget.exe
# becomes available system-wide at C:\Program Files\WindowsApps\...
# SYSTEM can then invoke winget for --scope machine installs.

{% set winget_url = 'https://github.com/microsoft/winget-cli/releases/download/v1.12.440/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle' %}
{% set winget_bundle = 'C:\\Windows\\Temp\\AppInstaller.msixbundle' %}
{% set managed_users = salt['pillar.get']('managed_users', []) %}
{% set bootstrap_user = managed_users[0] if managed_users else 'Administrator' %}
{% set service_user = salt['pillar.get']('service_user', {}) %}
{% set svc_name = service_user.get('name', 'cozy-salt-svc') %}

winget-bundle-fetch:
  file.managed:
    - name: {{ winget_bundle }}
    - source: {{ winget_url }}
    - makedirs: True
    - skip_verify: True

# Install winget as real user (SYSTEM cannot install AppX packages)
winget-install-user:
  cmd.run:
    - name: Add-AppxPackage -Path "{{ winget_bundle }}"
    - shell: powershell
    - runas: {{ bootstrap_user }}
    - unless: |
        powershell -Command "
          if (Get-AppxPackage Microsoft.DesktopAppInstaller -ErrorAction SilentlyContinue) {
            exit 0
          } else {
            exit 1
          }
        "
    - require:
      - file: winget-bundle-fetch
      - user: {{ bootstrap_user }}_user
      - user: {{ svc_name }}_service_account

# ============================================================================
# BOOTSTRAP: Install Chocolatey (Windows package manager)
# ============================================================================
chocolatey-install:
  cmd.run:
    - shell: pwsh
    - runas: SYSTEM
    - name: |
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    - unless: |
        pwsh -NoLogo -Command "
          if (Get-Command choco -ErrorAction SilentlyContinue) {
            exit 0
          } else {
            exit 1
          }
        "

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


# Install Winget runtime packages, system scope
{% if packages.windows.winget_runtimes is defined %}
{% for category, pkgs in packages.windows.winget_runtimes.items() %}
{% for pkg in pkgs %}
winget_runtime_{{ pkg | replace('.', '_') | replace('-', '_') }}:
  cmd.run:
    - shell: pwsh
    - runas: SYSTEM
    - name: winget install --scope machine --accept-source-agreements --accept-package-agreements --exact --id {{ pkg }}
    - unless: >
        pwsh -NoLogo -Command "
          if (winget list --scope machine --exact --id {{ pkg }} | Select-String -Quiet -Pattern '{{ pkg }}') {
            exit 0
          } else {
            exit 1
          }
        "
    - require:
      - cmd: winget-install-user
{% endfor %}
{% endfor %}
{% endif %}

# Install Winget packages by category, as machine scope
{% if packages.windows.winget_system is defined %}
{% for category, pkgs in packages.windows.winget_system.items() %}
{% for pkg in pkgs %}
winget_{{ pkg | replace('.', '_') | replace('-', '_') }}:
  cmd.run:
    - shell: pwsh
    - runas: SYSTEM
    - name: winget install --scope machine --accept-source-agreements --accept-package-agreements  --exact --id {{ pkg }}
    - unless: >
        pwsh -NoLogo -Command "
          if (winget list --scope machine --exact --id {{ pkg }} | Select-String -Quiet -Pattern '{{ pkg }}') {
            exit 0
          } else {
            exit 1
          }
        "
    - require:
      - cmd: winget-install-user
{% endfor %}
{% endfor %}
{% endif %}

# Installs userland packages, user scope ( similar to  AllUsers )
{% set users = salt['pillar.get']('managed_users', []) %}
{% for user in users %}
  {% for category, pkgs in packages.windows.winget_userland.items() %}
    {% for pkg in pkgs %}
winget_userland_{{ user | replace('.', '_') | replace('-', '_') }}_{{ pkg | replace('.', '_') | replace('-', '_') }}:
  cmd.run:
    - name: winget install --scope user --accept-source-agreements --accept-package-agreements  --exact --id {{ pkg }}
    - runas: {{ user }}
    - shell: pwsh
    - unless: >
        pwsh -NoLogo -Command "
          if (winget list --scope user --exact --id {{ pkg }} | Select-String -Quiet -Pattern '{{ pkg }}') {
            exit 0
          } else {
            exit 1
          }
        "
    # - require:
    #   - cmd: winget-install-system
    {% endfor %}
  {% endfor %}
{% endfor %}

# PowerShell Modules (from powershell_gallery)
{% set all_pwsh_modules = packages.windows.get('powershell_gallery', []) %}
{% if all_pwsh_modules %}
{% for module in all_pwsh_modules %}
pwsh_module_{{ module | replace('.', '_') | replace('-', '_') }}:
  cmd.run:
    - shell: pwsh
    - runas: SYSTEM
    - name: >
        pwsh -NoLogo -Command "
          Install-Module -Name '{{ module }}' -Scope AllUsers -AllowClobber -SkipPublisherCheck -Force -Repository PSGallery
        "
    - unless: >
        pwsh -NoLogo -Command "
          if (Get-InstalledModule -Name '{{ module }}' -ErrorAction SilentlyContinue) {
            exit 0
          } else {
            exit 1
          }
        "
{% endfor %}
{% endif %}

# Enable Chocolatey features
{% for feature in enable_choco_features %}
choco_feature_{{ feature }}_enabled:
  cmd.run:
    - name: choco feature enable -n={{ feature }}
    - shell: pwsh
    - require:
      - cmd: chocolatey-install
{% endfor %}

# Install Chocolatey packages
{% if packages.windows.choco is defined %}
{% for pkg in packages.windows.choco %}
choco_{{ pkg | replace('.', '_') | replace('-', '_') }}:
  chocolatey.installed:
    - name: {{ pkg }}
    - require:
      - cmd: chocolatey-install
{% endfor %}
{% endif %}
