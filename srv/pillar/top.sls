#!jinja|yaml
# ═══════════════════════════════════════════════════════════════
# Pillar Load Order: common → os → dist → class → users → host
# Each layer can overwrite or append to previous layers
# Host is LAST = final word on machine-specific overrides
# ═══════════════════════════════════════════════════════════════
{% set hostname = grains.get('id', '') %}
{% set host_file = '/srv/pillar/host/' ~ hostname ~ '.sls' %}

base:
  # Layer 1: Common defaults
  '*':
    - common.users
    - common.network
    - common.paths
    - common.versions
    - common.scheduler
    - mgmt
    - secrets

  # Layer 2: OS-family
  'G@os_family:Windows':
    - match: compound
    - windows

  'G@os_family:Debian or G@os_family:RedHat or G@os_family:Arch':
    - match: compound
    - linux

  # Layer 3: Distribution
  'G@os_family:Arch':
    - match: compound
    - dist.arch

  # Layer 4: Hardware class
  'G@biosvendor:Valve and G@boardname:Galileo':
    - match: compound
    - hardware.galileo

  'G@biosvendor:"EDK II" and G@boardname:Jetson':
    - match: compound
    - hardware.jetson

  # Layer 5: Per-user configs
  '* and not G@id:__NEVER_MATCH__':
    - match: compound
    - users.admin
    - users.vegcom
    - users.eve
    - users.june

  # Layer 6: Host-specific (FINAL - overrides everything)
{% if salt['file.file_exists'](host_file) %}
  '{{ hostname }}':
    - host.{{ hostname }}
{% endif %}
