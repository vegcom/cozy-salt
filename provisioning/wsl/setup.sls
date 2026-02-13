# WSL Setup State
# Provisions WSL with Docker and Salt Master
# This is a reference file - actual provisioning is done via shell scripts

# Deploy provisioning scripts
/opt/cozy:
  file.directory:
    - user: {{ grains['username'] }}
    - group: {{ grains['username'] }}
    - makedirs: True

{% for script in ['docker.sh', 'salt.sh', 'enable-openssh.sh'] %}
/opt/cozy/{{ script }}:
  file.managed:
    - source: salt://provisioning/wsl/files/opt-cozy/{{ script }}
    - user: {{ grains['username'] }}
    - group: {{ grains['username'] }}
    - mode: "0755"
    - require:
      - file: /opt/cozy
{% endfor %}

# Docker proxy config (shared with linux)
/opt/cozy/docker-proxy.yaml:
  file.managed:
    - source: salt://provisioning/common/files/opt-cozy-docker/docker-proxy.yaml
    - user: {{ grains['username'] }}
    - group: {{ grains['username'] }}
    - mode: "0644"
    - require:
      - file: /opt/cozy

# Instructions state (just outputs what to do next)
wsl_setup_instructions:
  test.show_notification:
    - text: |
        WSL provisioning scripts deployed to /opt/cozy/

        # TODO: Move to /opt/cozy/docker
        Run in order:
        1. /opt/cozy/docker.sh       - Install Docker
        2. /opt/cozy/enable-openssh.sh - Set up SSH on port 2222
        3. /opt/cozy/salt.sh         - Clone repo and start Salt Master

        Then on Windows:
        docker context create wsl --docker "host=tcp://localhost:2375"
