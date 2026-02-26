# Docker Socket Proxy for remote TCP access
# Exposes Docker daemon on TCP 2375 for Windows/WSL access
# Only deployed on Debian systems with Docker installed

{% set is_container = salt['file.file_exists']('/.dockerenv') or
                      salt['file.file_exists']('/run/.containerenv') %}
{# Path configuration from pillar with defaults #}
{% set cozy_path = salt['pillar.get']('install_paths:cozy:linux', '/opt/cozy/bin') %}
{% set cozy_docker = salt['pillar.get']('install_paths:docker:linux', '/opt/cozy/docker') %}

{% set docker_enabled = salt['pillar.get']('docker_enabled', False) %}
{% set docker_proxy_config = cozy_docker ~ '/docker-proxy.yaml' %}

{% if not is_container %}
{% if docker_enabled %}
# Deploy docker-proxy docker-compose file
docker_proxy_file:
  file.managed:
    - name: {{ docker_proxy_config }}
    - source: salt://common/files/opt-cozy-docker/docker-proxy.yaml
    - mode: "0644"
    - user: root
    - group: root
    - makedirs: True
{%- if grains['os_family'] != 'Arch' %}
    - require:
      - cmd: docker_install
{% endif %}

# Start docker-proxy service
docker_proxy_service:
  cmd.run:
    - name: docker compose -f {{ docker_proxy_config }} up -d
    - require:
      - file: docker_proxy_file
    - unless: docker ps | grep -q docker-socket-proxy
{% else %}
# Docker proxy skipped (non-Debian or container)
docker_proxy_file:
  test.nop:
    - name: Skipping Docker proxy

docker_proxy_service:
  test.nop:
    - name: Skipping Docker proxy service
{% endif %}
{% endif %}
