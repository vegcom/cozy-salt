# Linux package installation (P2 - Capability-based)
# Packages organized by capability/purpose with per-distro mappings
# See provisioning/packages.sls for full package definitions

{% import_yaml 'packages.sls' as packages %}
{% set os_family = grains['os_family'] %}
{% set os_name = 'ubuntu' if os_family == 'Debian' else 'rhel' %}

# Install Docker using official installer script (handles repo setup and GPG keys automatically)
# Works on Debian, Ubuntu, CentOS, RHEL, Fedora via get.docker.com
docker_install:
  cmd.run:
    - name: curl -fsSL https://get.docker.com -o /tmp/get-docker.sh && sh /tmp/get-docker.sh
    - creates: /usr/bin/docker
    - require_in:
      - pkg: core_utils_packages

# Force apt update after Docker repo is added (Debian/Ubuntu only)
{% if os_family == 'Debian' %}
apt_update_with_override:
  cmd.run:
    - name: apt-get update --allow-releaseinfo-change
    - require:
      - cmd: docker_install
{% endif %}

# ============================================================================
# Install packages by capability (grouped and distro-aware)
# ============================================================================

# Core utilities required on all systems
core_utils_packages:
  pkg.installed:
    - pkgs: {{ packages[os_name].core_utils[os_name] | tojson }}
{% if os_family == 'Debian' %}
    - require:
      - cmd: apt_update_with_override
{% endif %}

# System monitoring and diagnostics tools
monitoring_packages:
  pkg.installed:
    - pkgs: {{ packages[os_name].monitoring[os_name] | tojson }}
    - require:
      - pkg: core_utils_packages
    - onfail_stop: True

# Shell customization and enhancements
shell_packages:
  pkg.installed:
    - pkgs: {{ packages[os_name].shell_enhancements[os_name] | tojson }}
    - require:
      - pkg: core_utils_packages
    - onfail_stop: True

# Build tools and compilers
build_packages:
  pkg.installed:
    - pkgs: {{ packages[os_name].build_tools[os_name] | tojson }}
    - require:
      - pkg: core_utils_packages
    - onfail_stop: True

# Networking tools
networking_packages:
  pkg.installed:
    - pkgs: {{ packages[os_name].networking[os_name] | tojson }}
    - require:
      - pkg: core_utils_packages
    - onfail_stop: True

# Compression and archive tools
compression_packages:
  pkg.installed:
    - pkgs: {{ packages[os_name].compression[os_name] | tojson }}
    - require:
      - pkg: core_utils_packages
    - onfail_stop: True

# Version control extras (git-lfs, gh, tig)
vcs_packages:
  pkg.installed:
    - pkgs: {{ packages[os_name].vcs_extras[os_name] | tojson }}
    - require:
      - pkg: core_utils_packages
    - onfail_stop: True

# Modern CLI tools (ripgrep, fd, bat, fzf)
# Note: Some not available in RHEL base repos
modern_cli_packages:
  pkg.installed:
    - pkgs: {{ packages[os_name].modern_cli[os_name] | tojson }}
    - require:
      - pkg: core_utils_packages
    - onfail_stop: True

# Security and certificates
security_packages:
  pkg.installed:
    - pkgs: {{ packages[os_name].security[os_name] | tojson }}
    - require:
      - pkg: core_utils_packages
    - onfail_stop: True

# Access control lists
acl_packages:
  pkg.installed:
    - pkgs: {{ packages[os_name].acl[os_name] | tojson }}
    - require:
      - pkg: core_utils_packages
    - onfail_stop: True

# Install KVM/Virtualization packages (only on designated test hosts)
# To enable, set pillar: host:capabilities:kvm: true
{% if salt['pillar.get']('host:capabilities:kvm', False) %}
kvm_packages:
  pkg.installed:
    - pkgs: {{ packages[os_name].kvm[os_name] | tojson }}
    - require:
      - pkg: core_utils_packages
    - onfail_stop: True

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
