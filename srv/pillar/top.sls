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
    - linux.k3s

  # Layer 3: Distribution
  'G@os_family:Arch':
    - match: compound
    - dist.arch

  # Layer 4: Hardware class
  'G@biosvendor:Valve and G@boardname:Galileo':
    - match: compound
    - hardware.galileo
    - users.deck

  'G@biosvendor:"EDK II" and G@boardname:Jetson':
    - match: compound
    - hardware.jetson
    - users.nvidia

  'G@kernelrelease:*rpt-rpi*':
    - match: compound
    - hardware.rpi


  # Layer 5: Per-user configs (gated on common managed_users)
  {% set users_dir = '/srv/pillar/users/' %}
  {% set skip_users = ['demo'] %}
  {% set common = salt['slsutil.renderer'](path='/srv/pillar/common/users.sls', default_renderer='jinja|yaml') %}
  {% set common_managed = common.get('managed_users', []) %}
  '* and not G@id:__NEVER_MATCH__':
    - match: compound
    {% for user_file in salt['file.find'](users_dir, type='f', name='*.sls') | sort %}
    {% set uname = user_file | replace(users_dir, '') | replace('.sls', '') %}
    {% if uname not in skip_users and uname in common_managed %}
    - users.{{ uname }}
    {% endif %}
    {% endfor %}

  # Layer 6: Host-specific (FINAL - overrides everything)
{% if salt['file.file_exists'](host_file) %}
  '{{ hostname }}':
    - host.{{ hostname }}
{% endif %}
