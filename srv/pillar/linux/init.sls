#!jinja|yaml
# Linux Pillar Data
# Configuration values for Linux minions

# =============================================================================
# CPU Architecture Detection
# =============================================================================
# Computed once here for reuse across distro-specific pillars
# Used by: Chaotic AUR mirror selection, cross-arch deployments
cpu_arch: "{{ 'aarch64' if salt['grains.get']('cpuarch') == 'aarch64' else 'x86_64' }}"

# User configuration
# Auto-detected from login user (defaults to root in containers)
{% if salt['grains.get']('virtual', '') in ['docker', 'container', 'lxc'] %}
  {# In containers, default to root unless minion_id suggests otherwise #}
  {% set detected_user = 'root' %}
{% else %}
  {# On bare metal/VMs, try to detect actual user #}
  {% set detected_user = salt['environ.get']('SUDO_USER') or salt['environ.get']('LOGNAME') or 'root' %}
{% endif %}
user:
  name: {{ detected_user }}

# Node.js version management via nvm
nvm:
  default_version: 'lts/*'

# Workstation role-based package selection
# Options: workstation-minimal, workstation-base (default), workstation-developer
# - workstation-minimal: Core utilities + shell only
# - workstation-base: Core + monitoring + vcs + modern CLI + security (suitable for most users)
# - workstation-developer: Base + build tools + networking + KVM (for developers/testing)
workstation_role: 'workstation-base'

# Host capabilities and services (optional - enable specific features)
host:
  capabilities:
    # KVM virtualization (required for Dockur Windows testing)
    # Enabled automatically when 'kvm-host' role is set in grains
    kvm: {{ 'kvm-host' in salt['grains.get']('roles', []) }}

  services:
    # SSH service - enabled by default on native systems, disabled in containers
    ssh_enabled: {{ not (salt['file.file_exists']('/.dockerenv') or salt['file.file_exists']('/run/.containerenv')) }}

# =============================================================================
# System Locales
# =============================================================================
# Locales to generate via locale-gen
# Added to /etc/locale.gen before running locale-gen
# Override in class/ or host/ pillar as needed
locales:
  - en_US.UTF-8 UTF-8
  - fr_FR.UTF-8 UTF-8
  - ja_JP.UTF-8 UTF-8
  - ko_KR.UTF-8 UTF-8
  - ru_RU.UTF-8 UTF-8
  - zh_CN.UTF-8 UTF-8
  - zh_TW.UTF-8 UTF-8

# =============================================================================
# Login Manager (SDDM) Configuration
# =============================================================================
# Manages SDDM display manager, theming, and autologin
# Disabled by default - enable in class/ or host/ pillar
linux:
  login_manager:
    sddm:
      enabled: false
      theme: astronaut          # SDDM theme name (astronaut, breeze, etc)
      deploy_fonts: true        # Deploy theme fonts to system
    autologin:
      user: false               # Username for autologin (false = disabled)

  # =============================================================================
  # Bluetooth Configuration
  # =============================================================================
  # Manages bluetooth service and configuration
  # Disabled by default - enable in class/ or host/ pillar
  bluetooth:
    enabled: false              # Enable bluetooth service

# =============================================================================
# Role-based Capability Mapping
# =============================================================================
# Each role defines a list of capabilities to install
# Capabilities correspond to package groups in provisioning/packages.sls
role_capabilities:
  workstation-minimal:
    - core_utils
    - shell_enhancements

  workstation-base:
    - core_utils
    - shell_enhancements
    - monitoring
    - compression
    - vcs_extras
    - modern_cli
    - security
    - acl

  workstation-developer:
    - core_utils
    - shell_enhancements
    - monitoring
    - compression
    - vcs_extras
    - modern_cli
    - security
    - acl
    - build_tools
    - networking
    - kvm

  workstation-full:
    - core_utils
    - shell_enhancements
    - monitoring
    - compression
    - vcs_extras
    - modern_cli
    - security
    - acl
    - build_tools
    - networking
    - kvm
    - interpreters
    - shell_history
    - modern_cli_extras
    - fonts
    - theming

# =============================================================================
# Capability Installation Metadata
# =============================================================================
# Defines HOW each capability installs (state names, dependencies, extras)
# Keys MUST match capability names in packages.sls and role_capabilities
#
# Supported flags:
#   state_name:      Salt state ID for pkg.installed (required)
#   is_foundation:   true = installs first, requires apt_update (only core_utils)
#   pillar_gate:     dot-path pillar key that must be True to install
#   has_service:     service name to enable after pkg install
#   has_user_groups: list of groups to add user to after pkg install
#
# To add a new capability:
#   1. Add packages to provisioning/packages.sls under each distro
#   2. Add entry here with state_name (and any flags)
#   3. Add to role_capabilities in srv/salt/linux/install.sls
# =============================================================================
capability_meta:
  core_utils:
    state_name: core_utils_packages
    is_foundation: true

  shell_enhancements:
    state_name: shell_packages

  monitoring:
    state_name: monitoring_packages

  compression:
    state_name: compression_packages

  vcs_extras:
    state_name: vcs_packages

  modern_cli:
    state_name: modern_cli_packages

  security:
    state_name: security_packages

  acl:
    state_name: acl_packages

  build_tools:
    state_name: build_packages

  networking:
    state_name: networking_packages

  kvm:
    state_name: kvm_packages
    pillar_gate: host:capabilities:kvm
    has_service: libvirtd
    has_user_groups:
      - kvm
      - libvirt

  interpreters:
    state_name: interpreter_packages

  shell_history:
    state_name: shell_history_packages

  modern_cli_extras:
    state_name: modern_cli_extras_packages

  fonts:
    state_name: font_packages

  theming:
    state_name: theming_packages
