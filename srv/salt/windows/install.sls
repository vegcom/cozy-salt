# Windows package installation
# Packages defined in provisioning/packages.sls

{% import_yaml 'packages.sls' as packages %}

# ============================================================================
# BOOTSTRAP: Download and install winget (Windows Package Manager)
# ============================================================================

{% set winget_url = 'https://github.com/microsoft/winget-cli/releases/download/v1.12.440/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle' %}
{% set winget_bundle = 'C:\\Windows\\Temp\\AppInstaller.msixbundle' %}

winget-bundle-fetch:
  file.managed:
    - name: {{ winget_bundle }}
    - source: {{ winget_url }}
    - makedirs: True
    - skip_verify: True

winget-install-system:
  cmd.run:
    - name: Add-AppxPackage -Path "{{ winget_bundle }}"
    - shell: powershell
    - runas: SYSTEM
    - unless: |
        powershell -NoProfile -Command "
          if (Get-AppxPackage Microsoft.DesktopAppInstaller -ErrorAction SilentlyContinue) {
            exit 0
          } else {
            exit 1
          }
        "
    - require:
      - file: winget-bundle-fetch

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
{% if packages.winget_runtimes is defined %}
{% for category, pkgs in packages.winget_runtimes.items() %}
{% for pkg in pkgs %}
winget_runtime_{{ pkg | replace('.', '_') | replace('-', '_') }}:
  cmd.run:
    - shell: pwsh
    - runas: SYSTEM
    - name: winget install --scope machine --accept-source-agreements --accept-package-agreements --exact --id {{ pkg }}
    - unless: >
        pwsh -NoLogo -NoProfile -Command "
          if (winget list --scope machine --exact --id {{ pkg }} | Select-String -Quiet -Pattern '{{ pkg }}') {
            exit 0
          } else {
            exit 1
          }
        "
    - require:
      - cmd: winget-install-system
{% endfor %}
{% endfor %}
{% endif %}

# Install Winget packages by category, as machine scope
{% if packages.winget_system is defined %}
{% for category, pkgs in packages.winget_system.items() %}
{% for pkg in pkgs %}
winget_{{ pkg | replace('.', '_') | replace('-', '_') }}:
  cmd.run:
    - shell: pwsh
    - runas: SYSTEM
    - name: winget install --scope machine --accept-source-agreements --accept-package-agreements  --exact --id {{ pkg }}
    - unless: >
        pwsh -NoLogo -NoProfile -Command "
          if (winget list --scope machine --exact --id {{ pkg }} | Select-String -Quiet -Pattern '{{ pkg }}') {
            exit 0
          } else {
            exit 1
          }
        "
    - require:
      - cmd: winget-install-system
{% endfor %}
{% endfor %}
{% endif %}

# Installs userland packages, user scope ( similar to  AllUsers )
{% set users = salt['pillar.get']('managed_users', []) %}
{% for user in users %}
  {% for category, pkgs in packages.winget_userland.items() %}
    {% for pkg in pkgs %}
winget_userland_{{ user | replace('.', '_') | replace('-', '_') }}_{{ pkg | replace('.', '_') | replace('-', '_') }}:
  cmd.run:
    - name: winget install --scope user --accept-source-agreements --accept-package-agreements  --exact --id {{ pkg }}
    - runas: {{ user }}
    - shell: pwsh
    - unless: >
        pwsh -NoLogo -NoProfile -Command "
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

# PowerShell Modules (from both powershell_modules and powershell_gallery sources)
{% set all_pwsh_modules = packages.get('powershell_modules', []) + packages.get('powershell_gallery', []) %}
{% if all_pwsh_modules %}
{% for module in all_pwsh_modules %}
pwsh_module_{{ module | replace('.', '_') | replace('-', '_') }}:
  cmd.run:
    - shell: pwsh
    - runas: SYSTEM
    - name: >
        pwsh -NoLogo -NoProfile -Command "
          Install-Module -Name '{{ module }}' -Scope AllUsers -AllowClobber -SkipPublisherCheck -Force -Repository PSGallery
        "
    - unless: >
        pwsh -NoLogo -NoProfile -Command "
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
{% endfor %}

# Install Chocolatey packages
{% if packages.choco is defined %}
{% for pkg in packages.choco %}
choco_{{ pkg | replace('.', '_') | replace('-', '_') }}:
  chocolatey.installed:
    - name: {{ pkg }}
{% endfor %}
{% endif %}
