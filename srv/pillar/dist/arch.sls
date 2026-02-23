#!jinja|yaml
# Arch Linux Pillar Data

{% if salt['grains.get']('virtual', '') in ['docker', 'container', 'lxc'] %}
  {% set detected_user = 'root' %}
{% else %}
  {% set detected_user = salt['environ.get']('SUDO_USER') or salt['environ.get']('LOGNAME') or salt['environ.get']('USER') or 'admin' %}
{% endif %}

user:
  name: {{ detected_user }}

aur_user: {{ detected_user }}

nvm:
  default_version: 'lts/*'

workstation_role: 'workstation-base'

host:
  capabilities:
    kvm: {{ 'kvm-host' in salt['grains.get']('roles', []) }}

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

steamdeck:
  sddm:
    theme: 'astronaut'
    deploy_fonts: true
  autologin:
    user: false
  bluetooth:
    enabled: true
