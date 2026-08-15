{#-
  TODO: carve it up into little pieces
  TODO: move comments w documentation into linux.dist.archlinux.init or README.md or something
#}
# Arch Linux package installation (Role-Aware)
# Packages organized by capability/purpose using yay (AUR helper)
# Role-based selection via workstation_role pillar:
#   - workstation-minimal: core + shell
#   - workstation-base: minimal + monitoring, compression, vcs, modern-cli, security, acl
#   - workstation-developer: base + build tools, networking, kvm
#   - workstation-full (default): all capabilities + interpreters, shells, CLI extras, fonts, theming, gui
# See provisioning/packages.sls for full package definitions
# See srv/pillar/arch/init.sls for capability_meta and aur_user

{%- set os_name = 'arch' %}
{%- set workstation_role = salt['pillar.get']('workstation_role', 'workstation-full') %}
{%- set capability_meta = salt['pillar.get']('capability_meta', {}) %}
{%- set service_user = salt['pillar.get']('aur_user', 'cozy-salt-svc') %}
{%- set github_token = salt['pillar.get']('github:access_token', '') %}

# Get role capabilities from pillar (centralized in srv/pillar/linux/init.sls)
{%- set role_capabilities = salt['pillar.get']('linux', {}) %}
{%- set capabilities = role_capabilities.get(workstation_role, role_capabilities.get('workstation-full', [])) %}

{#- TODO: move to init.sls #}
include:
  - linux.gpu
  - linux.docker

{#- TODO: install.sls to be written and wired in at a later time #}
{%- from '_macros/packages.sls' import get_packages %}
{%- set packages = get_packages() | load_json %}
{%- set service_user = salt['pillar.get']('aur_user', 'cozy-salt-svc') %}

# ============================================================================
# FOUNDATION: core_utils via yay (runs first, others depend on this)
# ============================================================================
{%- if 'core_utils' in capabilities and 'core_utils' in packages.get(os_name, {}) %}
{%- set core_meta = capability_meta.get('core_utils', {'state_name': 'core_utils_packages'}) %}
{{ core_meta.state_name }}:
  yay.installed:
    - pkgs: {{ packages[os_name].core_utils | tojson }}
    - runas: {{ service_user }}
    - require:
      - cmd: yay_install
{%- endif %}

# ============================================================================
# CAPABILITIES: Loop through all non-foundation capabilities via yay
# ============================================================================
{%- for cap_key, cap_meta in capability_meta.items() %}
{# Skip foundation (handled above) and capabilities not in current role #}
{%- if not cap_meta.get('is_foundation', false) and cap_key in capabilities %}
{# Check packages exist for this distro and list is non-empty #}
{%- if packages.get(os_name, {}).get(cap_key) %}
{# Check pillar gate if defined (e.g., kvm needs host:capabilities:kvm) #}
{%- set pillar_gate = cap_meta.get('pillar_gate') %}
{%- if not pillar_gate or salt['pillar.get'](pillar_gate, False) %}

# --- {{ cap_key }} ---
{{ cap_meta.state_name }}:
  yay.installed:
    - pkgs: {{ packages[os_name][cap_key] | tojson }}
    - runas: {{ service_user }}
    - require:
      - yay: core_utils_packages

{# Post-install: Enable service if specified #}
{%- if cap_meta.get('has_service') %}
{{ cap_meta.has_service }}_service:
  service.running:
    - name: {{ cap_meta.has_service }}
    - enable: True
    - require:
      - yay: {{ cap_meta.state_name }}
{%- endif %}

{# Post-install: Add user to groups if specified #}
{%- if cap_meta.get('has_user_groups') %}
{{ cap_key }}_user_groups:
  user.present:
    - name: {{ service_user }}
    - groups: {{ cap_meta.has_user_groups | tojson }}
    - remove_groups: False
    - require:
      - yay: {{ cap_meta.state_name }}
{%- endif %}

{%- endif %}{# pillar_gate #}
{%- endif %}{# packages exist #}
{%- endif %}{# not foundation and in capabilities #}
{%- endfor %}

# ============================================================================
# PACKAGES ABSENT: pillar-defined packages to remove (before extras)
# ============================================================================
{%- set packages_absent = salt['pillar.get']('packages_absent:' ~ os_name, {}) %}
{%- set absent_nodeps = packages_absent.get('nodeps', []) %}
{%- set absent_normal = packages_absent.get('normal', []) %}

{%- if absent_nodeps %}
packages_absent_nodeps:
  cmd.run:
    - name: pacman -Rdd --noconfirm {{ absent_nodeps | join(' ') }} || true
    - require:
      - yay: core_utils_packages
{%- endif %}

{%- if absent_normal %}
  {%- for package in absent_normal %}
packages_absent_normal_{{ package }}:
  pkg.removed:
    - pkgs: {{ absent_normal | tojson }}
    - require:
      - yay: core_utils_packages
  {%- endfor %}
{%- endif %}

# ============================================================================
# PACKAGES EXTRA: pillar-defined additional packages per capability
# ============================================================================
{%- set packages_extra = salt['pillar.get']('packages_extra:' ~ os_name, {}) %}
{%- for cap_key, extra_pkgs in packages_extra.items() %}
{%- if extra_pkgs %}

# --- extra: {{ cap_key }} ---
packages_extra_{{ cap_key }}:
  yay.installed:
    - pkgs: {{ extra_pkgs | tojson }}
    - runas: {{ service_user }}
    - require:
      - yay: core_utils_packages
{%- if absent_nodeps | tojson %}
      - cmd: packages_absent_nodeps
{%- endif %}
{%- endif %}
{%- endfor %}
