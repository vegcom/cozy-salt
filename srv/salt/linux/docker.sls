# Docker installation and repository configuration
# Handles Debian, Ubuntu, Kali, WSL, and RHEL systems
# Debian-specific repo fixes live in linux/dist/ubuntu_noble.sls

{% set os_family = grains['os_family'] %}

# Install Docker
# Arch: managed via yay
# RHEL/Rocky: get.docker.com doesn't support Rocky — use Docker CE repo directly
# Debian/Ubuntu: use official convenience script (handles repo + GPG)
{% if os_family == 'Arch' %}
docker_install:
  test.nop:
    - name: Docker managed via yay on Arch
{% elif os_family == 'RedHat' %}
docker_repo:
  cmd.run:
    - name: dnf -y install dnf-plugins-core && dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
    - creates: /etc/yum.repos.d/docker-ce.repo

docker_install:
  cmd.run:
    - name: dnf -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    - creates: /usr/bin/docker
    - require:
      - cmd: docker_repo
{% else %}
docker_install:
  cmd.run:
    - name: curl -fsSL https://get.docker.com -o /tmp/get-docker.sh && sh /tmp/get-docker.sh
    - creates: /usr/bin/docker
{% endif %}
