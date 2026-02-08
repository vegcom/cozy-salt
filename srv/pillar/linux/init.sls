#!jinja|yaml
# Linux Pillar Data

{% set cpu_arch = 'aarch64' if salt['grains.get']('cpuarch') == 'aarch64' else 'x86_64' %}
cpu_arch: {{ cpu_arch }}

{% if salt['grains.get']('virtual', '') in ['docker', 'container', 'lxc'] %}
  {% set detected_user = 'root' %}
{% else %}
  {% set detected_user = salt['environ.get']('SUDO_USER') or salt['environ.get']('LOGNAME') or 'root' %}
{% endif %}
user:
  name: {{ detected_user }}

nvm:
  default_version: 'lts/*'

workstation_role: 'workstation-base'

host:
  capabilities:
    kvm: {{ 'kvm-host' in salt['grains.get']('roles', []) }}
  services:
    ssh_enabled: {{ not (salt['file.file_exists']('/.dockerenv') or salt['file.file_exists']('/run/.containerenv')) }}

locales:
  - en_US.UTF-8 UTF-8
  - fr_FR.UTF-8 UTF-8
  - ja_JP.UTF-8 UTF-8
  - ko_KR.UTF-8 UTF-8
  - ru_RU.UTF-8 UTF-8
  - zh_CN.UTF-8 UTF-8
  - zh_TW.UTF-8 UTF-8

linux:
  login_manager:
    sddm:
      enabled: false
      theme: astronaut
      deploy_fonts: true
    autologin:
      user: false
  bluetooth:
    enabled: false

role_capabilities:
  minimal: []  # No pkg capabilities - just homebrew, ssh-keys, dotfiles

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
