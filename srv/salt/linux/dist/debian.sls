# Debian/Ubuntu package installation (Role-Aware)
# Packages organized by capability/purpose with per-distro mappings
# Uses apt for package management
# See provisioning/packages.sls for full package definitions
# See srv/pillar/linux/init.sls for capability_meta (installation behavior)

{% import_yaml 'packages.sls' as packages %}
{% set os_name = 'ubuntu' %}
{% set workstation_role = salt['pillar.get']('workstation_role', 'workstation-full') %}
{% set capability_meta = salt['pillar.get']('capability_meta', {}) %}

# Define capability sets per role
{% set role_capabilities = {
  'workstation-minimal': ['core_utils', 'shell_enhancements'],
  'workstation-base': ['core_utils', 'shell_enhancements', 'monitoring', 'compression', 'vcs_extras', 'modern_cli', 'security', 'acl'],
  'workstation-developer': ['core_utils', 'shell_enhancements', 'monitoring', 'compression', 'vcs_extras', 'modern_cli', 'security', 'acl', 'build_tools', 'networking', 'kvm'],
  'workstation-full': ['core_utils', 'shell_enhancements', 'monitoring', 'compression', 'vcs_extras', 'modern_cli', 'security', 'acl', 'build_tools', 'networking', 'kvm']
} %}

{% set capabilities = role_capabilities.get(workstation_role, role_capabilities['workstation-full']) %}

include:
  - common.docker
  - common.gpu

# ============================================================================
# FOUNDATION: core_utils (runs first, others depend on this)
# ============================================================================
{% if 'core_utils' in capabilities and 'core_utils' in packages.get(os_name, {}) %}
{% set core_meta = capability_meta.get('core_utils', {'state_name': 'core_utils_packages'}) %}
{{ core_meta.state_name }}:
  pkg.installed:
    - pkgs: {{ packages[os_name].core_utils | tojson }}
    - require:
      - cmd: apt_update_with_override
{% endif %}

# ============================================================================
# CAPABILITIES: Loop through all non-foundation capabilities
# ============================================================================
{% for cap_key, cap_meta in capability_meta.items() %}
{% if not cap_meta.get('is_foundation', false) and cap_key in capabilities %}
{% if cap_key in packages.get(os_name, {}) %}
{% set pillar_gate = cap_meta.get('pillar_gate') %}
{% if not pillar_gate or salt['pillar.get'](pillar_gate, False) %}

# --- {{ cap_key }} ---
{{ cap_meta.state_name }}:
  pkg.installed:
    - pkgs: {{ packages[os_name][cap_key] | tojson }}
    - require:
      - pkg: core_utils_packages
    - onfail_stop: True

{% if cap_meta.get('has_service') %}
{{ cap_meta.has_service }}_service:
  service.running:
    - name: {{ cap_meta.has_service }}
    - enable: True
    - require:
      - pkg: {{ cap_meta.state_name }}
{% endif %}

{% if cap_meta.get('has_user_groups') %}
{% set user = salt['pillar.get']('user:name', 'admin') %}
{{ cap_key }}_user_groups:
  user.present:
    - name: {{ user }}
    - groups: {{ cap_meta.has_user_groups | tojson }}
    - remove_groups: False
    - require:
      - pkg: {{ cap_meta.state_name }}
{% endif %}

{% endif %}
{% endif %}
{% endif %}
{% endfor %}
