#!jinja|yaml
# Nvidia user configuration
{% set docker_enabled = salt['pillar.get']('docker_enabled', False) %}

users:
  nvidia:
    fullname: Nvidia SDK - A provisioned user for Jetpack
    shell: /bin/bash
    home_prefix: /home
    uid: 4002
    gid: 4002
    ssh_keys: []
    linux_groups:
{% if docker_enabled %}
      - docker
{% endif %}
      - libvirt
      - kvm
