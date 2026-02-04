# Linux package installation dispatcher
# Routes to distro-specific install state based on os_family

{% set os_family = grains['os_family'] %}
{% set os_lower = grains['os'] | lower %}

# Distro alias resolution (kali->debian, rocky->rhel, manjaro->arch, etc.)
{% set aliases = salt['pillar.get']('distro_aliases', {}) %}
{% set distro_key = aliases.get(os_lower, os_family | lower) %}

# Include appropriate distro-specific install state
{% if distro_key == 'debian' or os_family == 'Debian' %}
include:
  - linux.dist.debian
{% elif distro_key == 'rhel' or os_family == 'RedHat' %}
include:
  - linux.dist.rhel
{% elif distro_key == 'arch' or os_family == 'Arch' %}
include:
  - linux.dist.archlinux
{% else %}
# Unknown Linux distro - unable to proceed
unknown_distro:
  test.fail_without_changes:
    - name: "Unsupported Linux distro: os_family={{ os_family }}, os={{ grains.get('os', 'unknown') }}"
{% endif %}
