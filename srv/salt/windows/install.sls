# Windows package installation
# Packages defined in provisioning/packages.sls

{% import_yaml 'packages.sls' as packages %}

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
    {% endfor %}
  {% endfor %}
{% endfor %}

# Powershell Modules
{% if packages.powershell_modules is defined %}
{% for module in packages.powershell_modules %}
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
          if (Get-InstalledModule -Name '{{ module }}' -ErrorAction SilentlyContinue|Select-String -Quiet -Pattern "{{ module }}") {
            exit 0
          } else {
            exit 1
          }
        "
{% endfor %}
{% endif %}

# PowerShell Gallery Modules
{% if packages.powershell_gallery is defined %}
{% for module in packages.powershell_gallery %}
pwsh_module_{{ module | replace('.', '_') | replace('-', '_') }}:
  cmd.run:
    - runas: SYSTEM
    - name: >
        pwsh -NoLogo -NoProfile -Command "
          Install-Module -Name '{{ module }}' -Scope AllUsers -AllowClobber -SkipPublisherCheck -Force -Repository PSGallery
        "
    - unless: >
        pwsh -NoLogo -NoProfile -Command "
          if (Get-InstalledModule -Name '{{ module }}' -ErrorAction SilentlyContinue|Select-String -Quiet -Pattern "{{ module }}") {
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
