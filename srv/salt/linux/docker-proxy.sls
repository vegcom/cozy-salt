# Docker Socket Proxy for remote TCP access
# Exposes Docker daemon on TCP 2375 for Windows/WSL access
# Only deployed on Debian systems with Docker installed

{% if grains['os_family'] == 'Debian' %}
# Deploy docker-proxy docker-compose file
docker_proxy_file:
  file.managed:
    - name: /opt/cozy/docker-proxy.yaml
    - source: salt://linux/files/opt-cozy/docker-proxy.yaml
    - mode: 644
    - user: root
    - group: root
    - makedirs: True
    - require:
      - cmd: docker_install  # Docker installation state

# Start docker-proxy service
docker_proxy_service:
  cmd.run:
    - name: docker compose -f /opt/cozy/docker-proxy.yaml up -d
    - require:
      - file: docker_proxy_file
    - unless: docker ps | grep -q docker-socket-proxy
{% else %}
# Docker proxy skipped on non-Debian systems (RHEL, etc.)
docker_proxy_file:
  test.nop:
    - name: Skipping Docker proxy deployment on non-Debian system

docker_proxy_service:
  test.nop:
    - name: Skipping Docker proxy service on non-Debian system
{% endif %}
