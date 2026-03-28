workstation_role: 'workstation-full'

host:
  capabilities:
    k3s: true
    kvm: true

k3s:
  role: agent
  kwargs: "--default-runtime=nvidia"

docker_enabled: true

users:
  wsl:
    fullname: Windows Subsystem for Linux
    shell: /bin/bash
    home_prefix: /home
    uid: 6000
    gid: 6000
    ssh_keys: []
    linux_groups:
      - docker
      - libvirt
      - kvm
