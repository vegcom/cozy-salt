# WSL Setup State
# Provisions WSL with Docker and Salt Master
# This is a reference file - actual provisioning is done via shell scripts

# Deploy provisioning scripts
/opt/cozy:
  file.directory:
    - user: {{ grains['username'] }}
    - group: {{ grains['username'] }}
    - makedirs: True

{% for script in ['docker.sh', 'salt.sh', 'enable-openssh.sh', 'docker-proxy.yaml'] %}
/opt/cozy/{{ script }}:
  file.managed:
    - source: salt://wsl/files/opt-cozy/{{ script }}
    - user: {{ grains['username'] }}
    - group: {{ grains['username'] }}
    - mode: {% if script.endswith('.sh') %}755{% else %}644{% endif %}
    - require:
      - file: /opt/cozy
{% endfor %}

# Instructions state (just outputs what to do next)
wsl_setup_instructions:
  test.show_notification:
    - text: |
        WSL provisioning scripts deployed to /opt/cozy/

        Run in order:
        1. /opt/cozy/docker.sh       - Install Docker
        2. /opt/cozy/enable-openssh.sh - Set up SSH on port 2222
        3. /opt/cozy/salt.sh         - Clone repo and start Salt Master

        Then on Windows:
        docker context create wsl --docker "host=tcp://localhost:2375"
