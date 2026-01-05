# Windows package installation
# Packages defined in provisioning/packages.sls

{% import_yaml 'packages.sls' as packages %}

# Install Winget runtime packages
{% if packages.winget_runtimes is defined %}
{% for category, pkgs in packages.winget_runtimes.items() %}
{% for pkg in pkgs %}
winget_runtime_{{ pkg | replace('.', '_') | replace('-', '_') }}:
  cmd.run:
    - name: winget install --accept-source-agreements --accept-package-agreements -h --scope machine --id {{ pkg }}
    - unless: winget list --scope machine --id {{ pkg }} | findstr "{{ pkg }}"
{% endfor %}
{% endfor %}
{% endif %}

# Install Winget packages by category
{% if packages.winget is defined %}
{% for category, pkgs in packages.winget.items() %}
{% for pkg in pkgs %}
winget_{{ pkg | replace('.', '_') | replace('-', '_') }}:
  cmd.run:
    - name: winget install --accept-source-agreements --accept-package-agreements -h --scope machine --id {{ pkg }}
    - unless: winget list --scope machine --id {{ pkg }} | findstr "{{ pkg }}"
{% endfor %}
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
