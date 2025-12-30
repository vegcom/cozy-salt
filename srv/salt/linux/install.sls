# Linux package installation
# Orchestration only - packages defined in provisioning/packages.sls

{% import_yaml 'packages.sls' as packages %}

# Install Docker using official installer script (handles repo setup and GPG keys automatically)
{% if grains['os_family'] == 'Debian' %}
docker_install:
  cmd.run:
    - name: curl -fsSL https://get.docker.com -o /tmp/get-docker.sh && sh /tmp/get-docker.sh
    - creates: /usr/bin/docker
    - require_in:
      - pkg: base_packages

# Force apt update after Docker repo is added
apt_update_with_override:
  cmd.run:
    - name: apt-get update --allow-releaseinfo-change
    - require:
      - cmd: docker_install
{% endif %}

# Install base packages from consolidated list
base_packages:
  pkg.installed:
    - pkgs:
{% if grains['os_family'] == 'Debian' %}
{% for pkg in packages.apt %}
      - {{ pkg }}
{% endfor %}
    - require:
      - cmd: apt_update_with_override
{% elif grains['os_family'] == 'RedHat' %}
{% for pkg in packages.dnf %}
      - {{ pkg }}
{% endfor %}
{% endif %}

# Install KVM/Virtualization packages (only on designated test hosts)
# To enable, set pillar: host:capabilities:kvm: true
{% if salt['pillar.get']('host:capabilities:kvm', False) %}
kvm_packages:
  pkg.installed:
    - pkgs:
{% if grains['os_family'] == 'Debian' %}
{% for pkg in packages.apt_kvm %}
      - {{ pkg }}
{% endfor %}
{% elif grains['os_family'] == 'RedHat' %}
{% for pkg in packages.dnf_kvm %}
      - {{ pkg }}
{% endfor %}
{% endif %}

# Enable and start libvirt service
libvirtd_service:
  service.running:
    - name: libvirtd
    - enable: True
    - require:
      - pkg: kvm_packages

# Add user to kvm and libvirt groups
{% set user = salt['pillar.get']('user:name', 'admin') %}
kvm_user_groups:
  user.present:
    - name: {{ user }}
    - groups:
      - kvm
      - libvirt
    - remove_groups: False
    - require:
      - pkg: kvm_packages
{% endif %}
