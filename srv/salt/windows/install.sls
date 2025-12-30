# Windows package installation - Role-Based (P2)
# Packages selected based on host_role from pillar (minimal/base/dev/gaming/full)
# Definitions in provisioning/windows/roles.sls

{% import_yaml 'windows/roles.sls' as roles %}

# Get host role from pillar, default to 'desktop' for standard installations
{% set host_role = salt['pillar.get']('host_role', 'desktop') %}
{% if host_role not in roles %}
  # Invalid role, fallback to base
  {% set host_role = 'base' %}
{% endif %}

{% set selected_role = roles[host_role] %}

echo "Windows package role: {{ host_role }}":
  cmd.run:
    - name: echo "Installing packages for role: {{ host_role }}"
    - shell: powershell

# Enable Chocolatey feature for remembered arguments on upgrades
choco_feature_remembered_args:
  cmd.run:
    - name: choco feature enable -n=useRememberedArgumentsForUpgrades
    - shell: powershell
    - unless: powershell -Command "choco feature list | Select-String -Pattern 'useRememberedArgumentsForUpgrades.*Enabled' -Quiet"

# Install Chocolatey packages for selected role
{% if selected_role.choco is defined %}
{% for pkg in selected_role.choco %}
choco_{{ pkg | replace('.', '_') | replace('-', '_') }}:
  chocolatey.installed:
    - name: {{ pkg }}
{% endfor %}
{% endif %}

# Install Winget packages for selected role
# Handles list-of-dicts structure from roles.sls
{% if selected_role.winget is defined %}
{% for category_dict in selected_role.winget %}
{% for category, packages in category_dict.items() %}
{% if packages is not string and packages is iterable and packages != 'all' %}
{% for pkg in packages %}
winget_{{ pkg | replace('.', '_') | replace('-', '_') }}:
  cmd.run:
    - name: winget install --id {{ pkg }} --accept-source-agreements --accept-package-agreements -h
    - unless: winget list --id {{ pkg }} | findstr /C:"{{ pkg }}"
{% endfor %}
{% elif packages == 'all' %}
# Note: 'all' marker means install entire category from base provisioning/packages.sls
# Implementation: iterate full category from packages.sls when role is 'full'
{% endif %}
{% endfor %}
{% endfor %}
{% endif %}

# Install Winget runtime packages for selected role
{% if selected_role.winget_runtimes is defined %}
{% for category, packages in selected_role.winget_runtimes.items() %}
{% if packages is not string and packages is iterable and packages != 'all' %}
{% for pkg in packages %}
winget_runtime_{{ pkg | replace('.', '_') | replace('-', '_') }}:
  cmd.run:
    - name: winget install --id {{ pkg }} --accept-source-agreements --accept-package-agreements -h
    - unless: winget list --id {{ pkg }} | findstr /C:"{{ pkg }}"
{% endfor %}
{% elif packages == 'all' %}
# Note: 'all' marker means install entire category from base provisioning/packages.sls
# Implementation: iterate full category from packages.sls when role is 'full'
{% endif %}
{% endfor %}
{% endif %}
