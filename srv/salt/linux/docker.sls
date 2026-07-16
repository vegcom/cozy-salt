# Docker installation and repository configuration
# Handles Debian, Ubuntu, Kali, WSL, and RHEL systems
# Debian-specific repo fixes live in linux/dist/ubuntu_noble.sls

{%- set os_family = grains['os_family'] %}
{%- set is_ci = salt['pillar.get']('SALT_CI', False) %}

{#- Build docker config by merging host pillar + class contributions #}
{%- set _docker_cfg = salt['pillar.get']('docker', {}) %}
{%- for cname in salt['pillar.get']('classes', []) %}
  {%- set _class = salt['slsutil.renderer']('/srv/pillar/class/' ~ cname ~ '.sls', default_renderer='jinja|yaml', ignore_missing=True) %}
  {%- if _class and _class.get('docker') %}
    {%- set _docker_cfg = salt['slsutil.merge'](_docker_cfg, _class['docker']) %}
  {%- endif %}
{%- endfor %}
{%- set docker_cfg = _docker_cfg %}
# Install Docker
# Arch: managed via yay
# RHEL/Rocky: get.docker.com doesn't support Rocky — use Docker CE repo directly
# Debian/Ubuntu: use official convenience script (handles repo + GPG)

{%- if is_ci %}
docker_install:
  cmd.run:
    - name: echo "Docker install skipped in CI"
    - creates: /bin/true
{%- elif os_family == 'Arch' %}
docker_install:
  test.nop:
    - name: Docker managed via yay on Arch
{%- elif os_family == 'RedHat' %}
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
{%- else %}
docker_install:
  cmd.run:
    - name: curl -fsSL https://get.docker.com -o /tmp/get-docker.sh && sh /tmp/get-docker.sh
    - creates: /usr/bin/docker
{%- endif %}

{%- if docker_cfg %}
docker_daemon_config:
  file.serialize:
    - name: /etc/docker/daemon.json
    - dataset: {{ docker_cfg }}
    - serializer: json
    - mode: "0644"
    - makedirs: True
    - merge_if_exists: True
    - require:
  {%- if os_family != 'Arch' %}
      - cmd: docker_install
  {%- endif %}
docker_service:
  service.running:
    - name: docker
    - enable: True
  {%- if docker_cfg %}
    - watch:
      - file: docker_daemon_config
  {%- endif %}
{%- endif %}

include:
  - linux.docker-proxy
  - linux.docker_compose
