# K3S installation via
# https://raw.githubusercontent.com/k3s-io/k3s/main/install.sh
# https://update.k3s.io/v1-release/channels
# https://documentation.suse.com/cloudnative/k3s/latest/en/installation/configuration.html
# https://documentation.suse.com/cloudnative/k3s/latest/en/cli/server.html
# https://documentation.suse.com/cloudnative/k3s/latest/en/cli/agent.html

{% set k3s_channel = salt['pillar.get']('k3s:channel', 'latest') %}
{% set k3s_role = salt['pillar.get']('k3s:role', 'agent') %}
{% set k3s_args = salt['pillar.get']('k3s:args', k3s_role + " " + '--flannel-backend=none --docker --debug') %}
{% set k3s_server = salt['pillar.get']('k3s:server', 'k3s-server') %}
{% set k3s_token = salt['pillar.get']('k3s:token') %}


k3s_download_script:
  file.managed:
    - name: /tmp/k3s-init.sh
    - source: https://raw.githubusercontent.com/k3s-io/k3s/main/install.sh
    - source_hash: https://raw.githubusercontent.com/k3s-io/k3s/main/install.sh.sha256sum
    - mode: 0755

k3s_setup_script:
  cmd.run:
    - name: bash /tmp/k3s-init.sh
    #- unless: command -v k3s
    - require:
      - file: k3s_download_script
    - env:
      - INSTALL_K3S_CHANNEL: "{{ k3s_channel }}"
      - INSTALL_K3S_EXEC: "{{ k3s_args }}"
      - K3S_TOKEN: "{{ k3s_token }}"
{%- if not k3s_role == "server" %}
      - K3S_URL: {{ k3s_server }}
{%- endif %}
