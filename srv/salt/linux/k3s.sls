# K3S installation via
# https://raw.githubusercontent.com/k3s-io/k3s/main/install.sh
# https://update.k3s.io/v1-release/channels
# https://documentation.suse.com/cloudnative/k3s/latest/en/installation/configuration.html
# https://documentation.suse.com/cloudnative/k3s/latest/en/cli/server.html
# https://documentation.suse.com/cloudnative/k3s/latest/en/cli/agent.html

{% set k3s_channel = salt['pillar.get']('k3s:channel', 'latest') %}
{% set k3s_role = salt['pillar.get']('k3s:role', 'agent') %}
{% set k3s_args = salt['pillar.get']('k3s:args', '--docker') %}
{% set k3s_exec = [k3s_role, k3s_args] | join(' ') %}
{% set k3s_host = salt['pillar.get']('k3s:server', 'k3s-server') %}
{% set k3s_auth = salt['pillar.get']('k3s:token') %}

k3s_download_script:
  file.managed:
    - name: /tmp/k3s-init.sh
    - source: https://raw.githubusercontent.com/k3s-io/k3s/main/install.sh
    - source_hash: https://raw.githubusercontent.com/k3s-io/k3s/main/install.sh.sha256sum
    - mode: 0755

k3s_setup_script:
  cmd.run:
    - name: bash /tmp/k3s-init.sh
    - require:
      - file: k3s_download_script
    - env:
      - INSTALL_K3S_FORCE_RESTART: "true"
      - INSTALL_K3S_SKIP_ENABLE: "true"
      - INSTALL_K3S_SKIP_START: "true"
      - INSTALL_K3S_CHANNEL: "{{ k3s_channel }}"
      - INSTALL_K3S_EXEC: "{{ k3s_exec }}"
      - K3S_TOKEN: "{{ k3s_auth }}"
{%- if not k3s_role == "server" %}
      - K3S_URL: {{ k3s_host }}
{%- endif %}

k3s_uninstall_script:
  cmd.run:
    - name: /usr/local/bin/k3s-uninstall.sh
    - onfail:
      - service: k3s_service_start
    - require:
      - cmd: k3s_setup_script

k3s_service_start:
  service.running:
    - name: k3s.service
    - enable: True
    - require:
      - cmd: k3s_setup_script
