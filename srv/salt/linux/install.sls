# Linux package installation (Role-Aware)
# Packages organized by capability/purpose with per-distro mappings
# Role-based selection via workstation_role pillar:
#   - workstation-minimal: core + shell
#   - workstation-base: minimal + monitoring, compression, vcs, modern-cli, security, acl
#   - workstation-developer: base + build tools, networking, kvm
#   - workstation-full (default): all capabilities
# See provisioning/packages.sls for full package definitions

{% import_yaml 'packages.sls' as packages %}
{% set os_family = grains['os_family'] %}
{% set os_name = 'ubuntu' if os_family == 'Debian' else 'rhel' %}
{% set workstation_role = salt['pillar.get']('workstation_role', 'workstation-full') %}

# Define capability sets per role
{% set role_capabilities = {
  'workstation-minimal': ['core_utils', 'shell_enhancements'],
  'workstation-base': ['core_utils', 'shell_enhancements', 'monitoring', 'compression', 'vcs_extras', 'modern_cli', 'security', 'acl'],
  'workstation-developer': ['core_utils', 'shell_enhancements', 'monitoring', 'compression', 'vcs_extras', 'modern_cli', 'security', 'acl', 'build_tools', 'networking', 'kvm'],
  'workstation-full': ['core_utils', 'shell_enhancements', 'monitoring', 'compression', 'vcs_extras', 'modern_cli', 'security', 'acl', 'build_tools', 'networking', 'kvm']
} %}

# Get capabilities for current role (default to full if unknown)
{% set capabilities = role_capabilities.get(workstation_role, role_capabilities['workstation-full']) %}

# Install Docker using official installer script (handles repo setup and GPG keys automatically)
# Works on Debian, Ubuntu, CentOS, RHEL, Fedora via get.docker.com
docker_install:
  cmd.run:
    - name: curl -fsSL https://get.docker.com -o /tmp/get-docker.sh && sh /tmp/get-docker.sh
    - creates: /usr/bin/docker
    - require_in:
      - pkg: core_utils_packages

# Fix Docker repo for Kali/WSL - get.docker.com creates broken repos
# Kali has no official Docker repo, must use Ubuntu noble
{% if os_family == 'Debian' %}
{% set is_kali = grains.get('os', '') == 'Kali' %}
{% set is_wsl = salt['file.file_exists']('/proc/version') and 'microsoft' in salt['cmd.run']('cat /proc/version 2>/dev/null || echo ""', python_shell=True).lower() %}

{% if is_kali or is_wsl %}
# Remove broken Docker repos created by get.docker.com
# Kali/WSL get wrong repos that 404
docker_repo_cleanup:
  cmd.run:
    - name: rm -f /etc/apt/sources.list.d/docker*.list /etc/apt/sources.list.d/archive_uri-*.list 2>/dev/null || true
    - require:
      - cmd: docker_install

# Create correct Docker repo using Ubuntu noble (officially supported)
docker_repo_fix:
  file.managed:
    - name: /etc/apt/sources.list.d/docker.list
    - contents: |
        # Docker repo for Kali/WSL - using Ubuntu noble (official supported)
        deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu noble stable
    - require:
      - cmd: docker_repo_cleanup

apt_update_with_override:
  cmd.run:
    - name: apt-get update --allow-releaseinfo-change
    - require:
      - file: docker_repo_fix
{% else %}
# Native Debian - just update after docker install
apt_update_with_override:
  cmd.run:
    - name: apt-get update --allow-releaseinfo-change
    - require:
      - cmd: docker_install
{% endif %}
{% endif %}

# ============================================================================
# Install packages by capability (role-aware, distro-aware)
# Only installs capabilities defined for the current workstation_role
# ============================================================================

# Core utilities - always first, required by others
{% if 'core_utils' in capabilities %}
core_utils_packages:
  pkg.installed:
    - pkgs: {{ packages[os_name].core_utils | tojson }}
{% if os_family == 'Debian' %}
    - require:
      - cmd: apt_update_with_override
{% endif %}
{% endif %}

# Shell customization and enhancements
{% if 'shell_enhancements' in capabilities %}
shell_packages:
  pkg.installed:
    - pkgs: {{ packages[os_name].shell_enhancements | tojson }}
    - require:
      - pkg: core_utils_packages
    - onfail_stop: True
{% endif %}

# System monitoring and diagnostics tools
{% if 'monitoring' in capabilities %}
monitoring_packages:
  pkg.installed:
    - pkgs: {{ packages[os_name].monitoring | tojson }}
    - require:
      - pkg: core_utils_packages
    - onfail_stop: True
{% endif %}

# Compression and archive tools
{% if 'compression' in capabilities %}
compression_packages:
  pkg.installed:
    - pkgs: {{ packages[os_name].compression | tojson }}
    - require:
      - pkg: core_utils_packages
    - onfail_stop: True
{% endif %}

# Version control extras (git-lfs, gh, tig)
{% if 'vcs_extras' in capabilities %}
vcs_packages:
  pkg.installed:
    - pkgs: {{ packages[os_name].vcs_extras | tojson }}
    - require:
      - pkg: core_utils_packages
    - onfail_stop: True
{% endif %}

# Modern CLI tools (ripgrep, fd, bat, fzf)
{% if 'modern_cli' in capabilities %}
modern_cli_packages:
  pkg.installed:
    - pkgs: {{ packages[os_name].modern_cli | tojson }}
    - require:
      - pkg: core_utils_packages
    - onfail_stop: True
{% endif %}

# Security and certificates
{% if 'security' in capabilities %}
security_packages:
  pkg.installed:
    - pkgs: {{ packages[os_name].security | tojson }}
    - require:
      - pkg: core_utils_packages
    - onfail_stop: True
{% endif %}

# Access control lists
{% if 'acl' in capabilities %}
acl_packages:
  pkg.installed:
    - pkgs: {{ packages[os_name].acl | tojson }}
    - require:
      - pkg: core_utils_packages
    - onfail_stop: True
{% endif %}

# Build tools and compilers (developer+ roles)
{% if 'build_tools' in capabilities %}
build_packages:
  pkg.installed:
    - pkgs: {{ packages[os_name].build_tools | tojson }}
    - require:
      - pkg: core_utils_packages
    - onfail_stop: True
{% endif %}

# Networking tools (developer+ roles)
{% if 'networking' in capabilities %}
networking_packages:
  pkg.installed:
    - pkgs: {{ packages[os_name].networking | tojson }}
    - require:
      - pkg: core_utils_packages
    - onfail_stop: True
{% endif %}

# KVM/Virtualization packages (developer+ roles AND host:capabilities:kvm pillar)
{% if 'kvm' in capabilities and salt['pillar.get']('host:capabilities:kvm', False) %}
kvm_packages:
  pkg.installed:
    - pkgs: {{ packages[os_name].kvm | tojson }}
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

# ============================================================================
# GPU Detection (for future targeting)
# ============================================================================

# Detect GPU type and set grain for future targeting
# Supports: nvidia, amd (Steam Deck), other (intel/generic/none)
detect_gpu_type:
  cmd.run:
    - name: |
        if lspci 2>/dev/null | grep -qi "NVIDIA"; then
          echo "nvidia"
        elif lspci 2>/dev/null | grep -qi "AMD\|Radeon\|AMDGPU"; then
          echo "amd"
        else
          echo "other"
        fi
    - stateful: False

set_gpu_grain:
  grains.present:
    - name: linux_gpu
    - value: other
    - require:
      - cmd: detect_gpu_type
