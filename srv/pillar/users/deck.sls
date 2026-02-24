#!jinja|yaml
# Deck user configuration
{% set docker_enabled = salt['pillar.get']('docker_enabled', False) %}

users:
  deck:
    fullname: deck
    shell: /bin/bash
    home_prefix: /home
    ssh_keys: []
    linux_groups:
{% if docker_enabled %}
      - docker
{% endif %}
      - libvirt
      - kvm
