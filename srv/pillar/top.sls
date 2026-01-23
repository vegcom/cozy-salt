#!jinja|yaml
{% set hostname = grains.get('id', '') %}
{% set host_file = '/srv/salt/pillar/host/' + hostname + '.sls' %}

base:
  # All systems get common configuration
  '*':
    - common.users
    - common.network
    - common.paths
    - common.versions
    - common.scheduler
    - secrets

  # Windows systems
  'G@os_family:Windows':
    - match: compound
    - windows

  # Linux systems (Debian, RedHat, Arch)
  'G@os_family:Debian or G@os_family:RedHat or G@os_family:Arch':
    - match: compound
    - linux

  # Arch Linux specific
  'G@os_family:Arch':
    - match: compound
    - dist.arch

  # Hardware class: Valve Galileo (Steam Deck)
  'G@biosvendor:Valve and G@boardname:Galileo':
    - match: compound
    - class.galileo


  # Host-specific configuration (if file exists)
  {% if salt['file.file_exists'](host_file) %}
  '*':
    - host.{{ hostname }}
  {% endif %}
