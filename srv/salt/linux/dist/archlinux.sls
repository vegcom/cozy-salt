# Arch Linux package installation (Role-Aware)
# Packages organized by capability/purpose using yay (AUR helper)
# Role-based selection via workstation_role pillar:
#   - workstation-minimal: core + shell
#   - workstation-base: minimal + monitoring, compression, vcs, modern-cli, security, acl
#   - workstation-developer: base + build tools, networking, kvm
#   - workstation-full (default): all capabilities + interpreters, shells, CLI extras, fonts, theming
# See provisioning/packages.sls for full package definitions
# See srv/pillar/arch/init.sls for capability_meta and aur_user

{% import_yaml 'packages.sls' as packages %}
{% set os_name = 'arch' %}
{% set workstation_role = salt['pillar.get']('workstation_role', 'workstation-full') %}
{% set capability_meta = salt['pillar.get']('capability_meta', {}) %}
{# TODO: prep for service_user will be pillar service_user: buildgirl probs #}
{% set service_user = salt['pillar.get']('aur_user', 'admin') %}
{% set github_token = salt['pillar.get']('github:access_token', '') %}

# Get role capabilities from pillar (centralized in srv/pillar/linux/init.sls)
{% set role_capabilities = salt['pillar.get']('linux', {}) %}
{% set capabilities = role_capabilities.get(workstation_role, role_capabilities.get('workstation-full', [])) %}

include:
  - common.gpu

# ============================================================================
# PACMAN DATABASE SYNC - Run before any package installation
# ============================================================================
pacman_sync:
  pacman.sync

# ============================================================================
# BOOTSTRAP: git + base-devel via pacman (required for yay bootstrap)
# These MUST use pacman directly since yay isn't installed yet
# ============================================================================
bootstrap_packages:
  pacman.installed:
    - pkgs:
      - git
      - base-devel
    - require:
      - pacman: pacman_sync

# ============================================================================
# YAY BOOTSTRAP: Clone and build yay-bin from AUR
# Runs as aur_user since makepkg cannot run as root
# ============================================================================
yay_build_dir:
  file.directory:
    - name: /home/{{ service_user }}/.cache/yay-bootstrap
    - user: {{ service_user }}
    - group: {{ service_user }}
    - mode: "0755"
    - makedirs: True
    - require:
      - pacman: bootstrap_packages
      # - user: {{ service_user }}_user

yay_clone:
  git.latest:
    - name: https://aur.archlinux.org/yay-bin.git
    - target: /home/{{ service_user }}/.cache/yay-bootstrap/yay-bin
    - user: {{ service_user }}
    - force_clone: True
    - require:
      - file: yay_build_dir
    - unless: which yay

yay_install:
  cmd.run:
    - name: makepkg -si --noconfirm
    - cwd: /home/{{ service_user }}/.cache/yay-bootstrap/yay-bin
    - runas: {{ service_user }}
    - env:
      - HOME: /home/{{ service_user }}
      - USER: {{ service_user }}
      - LANG: C.UTF-8
      - PATH: /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
    - require:
      - git: yay_clone
    - unless: which yay

# ============================================================================
# FOUNDATION: core_utils via yay (runs first, others depend on this)
# ============================================================================
{% if 'core_utils' in capabilities and 'core_utils' in packages.get(os_name, {}) %}
{% set core_meta = capability_meta.get('core_utils', {'state_name': 'core_utils_packages'}) %}
{{ core_meta.state_name }}:
  yay.installed:
    - pkgs: {{ packages[os_name].core_utils | tojson }}
    - runas: {{ service_user }}
    - require:
      - cmd: yay_install
{% endif %}

# ============================================================================
# CAPABILITIES: Loop through all non-foundation capabilities via yay
# ============================================================================
{% for cap_key, cap_meta in capability_meta.items() %}
{# Skip foundation (handled above) and capabilities not in current role #}
{% if not cap_meta.get('is_foundation', false) and cap_key in capabilities %}
{# Check packages exist for this distro #}
{% if cap_key in packages.get(os_name, {}) %}
{# Check pillar gate if defined (e.g., kvm needs host:capabilities:kvm) #}
{% set pillar_gate = cap_meta.get('pillar_gate') %}
{% if not pillar_gate or salt['pillar.get'](pillar_gate, False) %}

# --- {{ cap_key }} ---
{{ cap_meta.state_name }}:
  yay.installed:
    - pkgs: {{ packages[os_name][cap_key] | tojson }}
    - runas: {{ service_user }}
    - require:
      - yay: core_utils_packages
    - onfail_stop: True

{# Post-install: Enable service if specified #}
{% if cap_meta.get('has_service') %}
{{ cap_meta.has_service }}_service:
  service.running:
    - name: {{ cap_meta.has_service }}
    - enable: True
    - require:
      - yay: {{ cap_meta.state_name }}
{% endif %}

{# Post-install: Add user to groups if specified #}
{% if cap_meta.get('has_user_groups') %}
{{ cap_key }}_user_groups:
  user.present:
    - name: {{ service_user }}
    - groups: {{ cap_meta.has_user_groups | tojson }}
    - remove_groups: False
    - require:
      - yay: {{ cap_meta.state_name }}
{% endif %}

{% endif %}{# pillar_gate #}
{% endif %}{# packages exist #}
{% endif %}{# not foundation and in capabilities #}
{% endfor %}
