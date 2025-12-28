# Linux package installation
# Orchestration only - packages defined in provisioning/packages.sls

{% import_yaml 'packages.sls' as packages %}

# Install base packages from consolidated list
base_packages:
  pkg.installed:
    - pkgs:
{% if grains['os_family'] == 'Debian' %}
{% for pkg in packages.apt %}
      - {{ pkg }}
{% endfor %}
{% elif grains['os_family'] == 'RedHat' %}
{% for pkg in packages.dnf %}
      - {{ pkg }}
{% endfor %}
{% endif %}
