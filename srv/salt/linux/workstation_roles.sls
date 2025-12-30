# Linux Workstation Role-Based Package Selection
# Selects package capabilities based on workstation_role pillar
# Detects and sets GPU type grain for specialized package selection

{% import_yaml "provisioning/packages.sls" as packages %}

{% set workstation_role = salt['pillar.get']('workstation_role', 'workstation-base') %}
{% set os_name = 'ubuntu' if grains['os_family'] == 'Debian' else 'rhel' %}

# Detect GPU type and set grain for future targeting
# Currently supports: nvidia, amd (Steam Deck), other (intel/generic/none)
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
  grains.present:
    - name: linux_gpu
    - value: other
    - require:
      - cmd: detect_gpu_type

# Install packages based on workstation role
{% if workstation_role == 'workstation-minimal' %}

# Minimal: Core utilities + shell only
minimal_core_packages:
  pkg.installed:
    - pkgs: {{ packages.core_utils[os_name] | tojson }}

minimal_shell_packages:
  pkg.installed:
    - pkgs: {{ packages.shell_enhancements[os_name] | tojson }}
    - require:
      - pkg: minimal_core_packages

{% elif workstation_role == 'workstation-base' %}

# Base: Minimal + monitoring + compression + vcs + modern-cli + security + acl
base_core_packages:
  pkg.installed:
    - pkgs: {{ packages.core_utils[os_name] | tojson }}

base_shell_packages:
  pkg.installed:
    - pkgs: {{ packages.shell_enhancements[os_name] | tojson }}
    - require:
      - pkg: base_core_packages

base_monitoring_packages:
  pkg.installed:
    - pkgs: {{ packages.monitoring[os_name] | tojson }}
    - require:
      - pkg: base_core_packages

base_compression_packages:
  pkg.installed:
    - pkgs: {{ packages.compression[os_name] | tojson }}
    - require:
      - pkg: base_core_packages

base_vcs_packages:
  pkg.installed:
    - pkgs: {{ packages.vcs_extras[os_name] | tojson }}
    - require:
      - pkg: base_core_packages

base_modern_cli_packages:
  pkg.installed:
    - pkgs: {{ packages.modern_cli[os_name] | tojson }}
    - require:
      - pkg: base_core_packages

base_security_packages:
  pkg.installed:
    - pkgs: {{ packages.security[os_name] | tojson }}
    - require:
      - pkg: base_core_packages

base_acl_packages:
  pkg.installed:
    - pkgs: {{ packages.acl[os_name] | tojson }}
    - require:
      - pkg: base_core_packages

{% elif workstation_role == 'workstation-developer' %}

# Developer: Base + build tools + networking + kvm
dev_core_packages:
  pkg.installed:
    - pkgs: {{ packages.core_utils[os_name] | tojson }}

dev_shell_packages:
  pkg.installed:
    - pkgs: {{ packages.shell_enhancements[os_name] | tojson }}
    - require:
      - pkg: dev_core_packages

dev_monitoring_packages:
  pkg.installed:
    - pkgs: {{ packages.monitoring[os_name] | tojson }}
    - require:
      - pkg: dev_core_packages

dev_compression_packages:
  pkg.installed:
    - pkgs: {{ packages.compression[os_name] | tojson }}
    - require:
      - pkg: dev_core_packages

dev_vcs_packages:
  pkg.installed:
    - pkgs: {{ packages.vcs_extras[os_name] | tojson }}
    - require:
      - pkg: dev_core_packages

dev_modern_cli_packages:
  pkg.installed:
    - pkgs: {{ packages.modern_cli[os_name] | tojson }}
    - require:
      - pkg: dev_core_packages

dev_security_packages:
  pkg.installed:
    - pkgs: {{ packages.security[os_name] | tojson }}
    - require:
      - pkg: dev_core_packages

dev_acl_packages:
  pkg.installed:
    - pkgs: {{ packages.acl[os_name] | tojson }}
    - require:
      - pkg: dev_core_packages

dev_build_packages:
  pkg.installed:
    - pkgs: {{ packages.build_tools[os_name] | tojson }}
    - require:
      - pkg: dev_core_packages

dev_networking_packages:
  pkg.installed:
    - pkgs: {{ packages.networking[os_name] | tojson }}
    - require:
      - pkg: dev_core_packages

dev_kvm_packages:
  pkg.installed:
    - pkgs: {{ packages.kvm[os_name] | tojson }}
    - require:
      - pkg: dev_core_packages

{% else %}

# Unknown role - skip package installation
unknown_role:
  test.nop:
    - name: Unknown workstation_role '{{ workstation_role }}' - skipping package installation

{% endif %}
