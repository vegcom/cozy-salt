#!jinja|yaml
# Nvidia user configuration
{% set docker_enabled = salt['pillar.get']('docker_enabled', False) %}

users:
  nvidia:
    fullname: Nvidia
    shell: /bin/bash
    home_prefix: /home
    ssh_keys: []
    linux_groups:
{% if docker_enabled %}
      - docker
{% endif %}
      - libvirt
      - kvm
