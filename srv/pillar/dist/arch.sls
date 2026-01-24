#!jinja|yaml
# Arch Linux Pillar Data
# Configuration values for Arch Linux minions (including Steam Deck)

# User configuration
# Auto-detected from login user (defaults to root in containers)
{% if salt['grains.get']('virtual', '') in ['docker', 'container', 'lxc'] %}
  {# In containers, default to root #}
  {% set detected_user = 'root' %}
{% else %}
  {# On bare metal try to detect actual user #}
  {% set detected_user = salt['environ.get']('SUDO_USER') or salt['environ.get']('LOGNAME') or salt['environ.get']('USER') or 'admin' %}
{% endif %}
user:
  name: {{ detected_user }}

# AUR helper user (yay cannot run as root)
# Defaults to detected user, override in host pillar if needed
aur_user: {{ detected_user }}

# Node.js version management via nvm
nvm:
  default_version: 'lts/*'

# Workstation role-based package selection
# Options: workstation-minimal, workstation-base (default), workstation-developer
# - workstation-minimal: Core utilities + shell only
# - workstation-base: Core + monitoring + vcs + modern CLI + security (suitable for most users)
# - workstation-developer: Base + build tools + networking + KVM (for developers/testing)
workstation_role: 'workstation-base'

# Host capabilities (optional - enable specific features)
host:
  capabilities:
    # KVM virtualization (required for Dockur Windows testing)
    # Enabled automatically when 'kvm-host' role is set in grains
    kvm: {{ 'kvm-host' in salt['grains.get']('roles', []) }}

# =============================================================================
# Capability Installation Metadata
# =============================================================================
# Defines HOW each capability installs (state names, dependencies, extras)
# Keys MUST match capability names in packages.sls and role_capabilities
#
# Arch-specific note: pacman doesn't have a separate "update" step like apt
# All package lists are installed after pacman -Sy syncs the database
#
# For more details, see srv/pillar/linux/init.sls
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

# =============================================================================
# =============================================================================
# Pacman Repository Configuration
# =============================================================================
# Manages /etc/pacman.conf repositories
# Chaotic AUR enabled by default for faster AUR package access
# Architecture (x86_64 or aarch64) computed in srv/pillar/linux/init.sls
{% set cpu_arch = salt['pillar.get']('cpu_arch', 'x86_64') %}
pacman:
  repos:
    kde-unstable:
      enabled: true
      Include: /etc/pacman.d/mirrorlist

    core:
      enabled: true
      Include: /etc/pacman.d/mirrorlist

    extra:
      enabled: true
      Include: /etc/pacman.d/mirrorlist

    multilib:
      enabled: true
      Include: /etc/pacman.d/mirrorlist

    chaotic_aur:
      enabled: false
      server: "https://chaotic.cx/chaotic-aur/{{ cpu_arch }}"
      
      

# Note: System locales are configured in srv/pillar/linux/init.sls as global defaults
# Override in host/ pillar if needed for specific systems

# =============================================================================
# Steam Deck Specific Configuration
# =============================================================================
steamdeck:
  # SDDM login manager theme
  # Options: 'astronaut', 'breeze', etc. (theme folder name in /usr/share/sddm/themes/)
  sddm:
    theme: 'astronaut'
    deploy_fonts: true

  # Autologin user (blank = disabled)
  autologin:
    user: false  # or: 'deck' to enable autologin

  # Bluetooth configuration
  bluetooth:
    enabled: true
