# Arch Linux package installation (Role-Aware)
# Packages organized by capability/purpose using Arch pacman packages
# Role-based selection via workstation_role pillar:
#   - workstation-minimal: core + shell
#   - workstation-base: minimal + monitoring, compression, vcs, modern-cli, security, acl
#   - workstation-developer: base + build tools, networking, kvm
#   - workstation-full (default): all capabilities
# See provisioning/packages.sls for full package definitions
# See srv/pillar/arch/init.sls for capability_meta (installation behavior)

{% import_yaml 'packages.sls' as packages %}
{% set os_family = grains['os_family'] %}
{% set os_name = 'arch' if os_family == 'Arch' else 'arch' %}
{% set workstation_role = salt['pillar.get']('workstation_role', 'workstation-full') %}
{% set capability_meta = salt['pillar.get']('capability_meta', {}) %}

# Define capability sets per role (orchestration logic - stays in state)
{% set role_capabilities = {
  'workstation-minimal': ['core_utils', 'shell_enhancements'],
  'workstation-base': ['core_utils', 'shell_enhancements', 'monitoring', 'compression', 'vcs_extras', 'modern_cli', 'security', 'acl'],
  'workstation-developer': ['core_utils', 'shell_enhancements', 'monitoring', 'compression', 'vcs_extras', 'modern_cli', 'security', 'acl', 'build_tools', 'networking', 'kvm'],
  'workstation-full': ['core_utils', 'shell_enhancements', 'monitoring', 'compression', 'vcs_extras', 'modern_cli', 'security', 'acl', 'build_tools', 'networking', 'kvm']
} %}

# Get capabilities for current role (default to full if unknown)
{% set capabilities = role_capabilities.get(workstation_role, role_capabilities['workstation-full']) %}

include:
  - common.docker
  - common.gpu

# ============================================================================
# PACMAN DATABASE SYNC - Run before any package installation
# ============================================================================
pacman_sync:
  cmd.run:
    - name: pacman -Sy --noconfirm
    - unless: test $(find /var/lib/pacman/sync -mmin -60 2>/dev/null | wc -l) -gt 0

# ============================================================================
# FOUNDATION: core_utils (runs first, others depend on this)
# ============================================================================
{% if 'core_utils' in capabilities and 'core_utils' in packages.get(os_name, {}) %}
{% set core_meta = capability_meta.get('core_utils', {'state_name': 'core_utils_packages'}) %}
{{ core_meta.state_name }}:
  pkg.installed:
    - pkgs: {{ packages[os_name].core_utils | tojson }}
    - require:
      - cmd: pacman_sync
{% endif %}

# ============================================================================
# CAPABILITIES: Loop through all non-foundation capabilities
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
  pkg.installed:
    - pkgs: {{ packages[os_name][cap_key] | tojson }}
    - require:
      - pkg: core_utils_packages
    - onfail_stop: True

{# Post-install: Enable service if specified #}
{% if cap_meta.get('has_service') %}
{{ cap_meta.has_service }}_service:
  service.running:
    - name: {{ cap_meta.has_service }}
    - enable: True
    - require:
      - pkg: {{ cap_meta.state_name }}
{% endif %}

{# Post-install: Add user to groups if specified #}
{% if cap_meta.get('has_user_groups') %}
{% set user = salt['pillar.get']('user:name', 'alarm') %}
{{ cap_key }}_user_groups:
  user.present:
    - name: {{ user }}
    - groups: {{ cap_meta.has_user_groups | tojson }}
    - remove_groups: False
    - require:
      - pkg: {{ cap_meta.state_name }}
{% endif %}

{% endif %}{# pillar_gate #}
{% endif %}{# packages exist #}
{% endif %}{# not foundation and in capabilities #}
{% endfor %}
