#!jinja|yaml
# Deck user configuration
{% set docker_enabled = salt['pillar.get']('docker_enabled', False) %}

users:
  deck:
    fullname: SteamDeck - A cozy little crashcart
    shell: /bin/bash
    home_prefix: /home
    uid: 4001
    gid: 4001
    ssh_keys: []
    linux_groups:
{% if docker_enabled %}
      - docker
{% endif %}
      - libvirt
      - kvm
      - nopasswdlogin
      - input
