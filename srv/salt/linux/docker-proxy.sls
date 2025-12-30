# Docker Socket Proxy for remote TCP access
# Exposes Docker daemon on TCP 2375 for Windows/WSL access
# Only deployed on non-Windows systems with Docker installed

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
