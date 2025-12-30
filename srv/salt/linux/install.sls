# Linux package installation
# Orchestration only - packages defined in provisioning/packages.sls

{% import_yaml 'packages.sls' as packages %}

# Add Docker repository (required for docker-buildx-plugin and other Docker packages)
{% if grains['os_family'] == 'Debian' %}
{% set os_lower = grains['os']|lower %}
{% set is_kali = grains['os'] == 'Kali' %}
{% set distro_component = 'kali-rolling' if is_kali else grains['oscodename'] %}

# Clean up stale sources to prevent apt-get update conflicts
clean_stale_sources:
  cmd.run:
    - name: rm -f /etc/apt/sources.list.d/kali* /etc/apt/sources.list.d/debian* 2>/dev/null || true
    - onlyif: test -d /etc/apt/sources.list.d

docker_repo:
  pkgrepo.managed:
    - name: deb [arch=amd64 trusted=yes] https://download.docker.com/linux/{{ os_lower }} {{ distro_component }} stable
    - file: /etc/apt/sources.list.d/docker.list
    - require:
      - cmd: clean_stale_sources

# Force apt update with --allow-releaseinfo-change to handle stale release info
apt_update_with_override:
  cmd.run:
    - name: apt-get update --allow-releaseinfo-change
    - require:
      - pkgrepo: docker_repo
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
