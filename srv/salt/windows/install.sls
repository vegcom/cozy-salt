# Windows package installation
# Packages defined in provisioning/packages.sls

{% import_yaml 'packages.sls' as packages %}


# Install Winget runtime packages, system scope
{% if packages.winget_runtimes is defined %}
{% for category, pkgs in packages.winget_runtimes.items() %}
{% for pkg in pkgs %}
winget_runtime_{{ pkg | replace('.', '_') | replace('-', '_') }}:
  cmd.run:
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
    - name: winget install --force --scope user --accept-source-agreements --accept-package-agreements  --exact --id {{ pkg }}
    - runas: {{ user }}
    - shell: pwsh
    # - unless: >
    #     pwsh -NoLogo -NoProfile -Command "
    #       if (winget list --scope user --exact --id {{ pkg }} | Select-String -Quiet -Pattern '{{ pkg }}') {
    #         exit 0
    #       } else {
    #         exit 1
    #       }
    #     "
    {% endfor %}
  {% endfor %}
{% endfor %}

# PWSH Modules
{% if packages.pwsh_modules is defined %}
{% for module in packages.pwsh_modules %}
pwsh_module_{{ module | replace('.', '_') | replace('-', '_') }}:
  cmd.run:
    - name: >
        pwsh -NoLogo -NoProfile -Command "
          if (-not (Get-InstalledModule -Name '{{ module }}' -ErrorAction SilentlyContinue)) {
            Install-Module -Name '{{ module }}' -Scope AllUsers -AllowClobber -SkipPublisherCheck -Force
          }
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

# Enable Chocolatey feature for remembered arguments on upgrades
choco_feature_remembered_args:
  cmd.run:
    - name: choco feature enable -n=useRememberedArgumentsForUpgrades
    - shell: powershell
    - unless: powershell -Command "choco feature list | Select-String -Pattern 'useRememberedArgumentsForUpgrades.*Enabled' -Quiet"

# Install Chocolatey packages
{% if packages.choco is defined %}
{% for pkg in packages.choco %}
choco_{{ pkg | replace('.', '_') | replace('-', '_') }}:
  chocolatey.installed:
    - name: {{ pkg }}
{% endfor %}
{% endif %}
