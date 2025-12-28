# Windows package installation
# Orchestration only - packages defined in provisioning/packages.sls

{% import_yaml 'packages.sls' as packages %}

# Install Chocolatey packages
{% for pkg in packages.choco %}
choco_{{ pkg | replace('.', '_') | replace('-', '_') }}:
  chocolatey.installed:
    - name: {{ pkg }}
{% endfor %}

# Install Winget packages
{% for pkg in packages.winget %}
winget_{{ pkg | replace('.', '_') | replace('-', '_') }}:
  cmd.run:
    - name: winget install --id {{ pkg }} --accept-source-agreements --accept-package-agreements -h
    - unless: winget list --id {{ pkg }} | findstr /C:"{{ pkg }}"
{% endfor %}
