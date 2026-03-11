# K3S installation via
# https://raw.githubusercontent.com/k3s-io/k3s/main/install.sh
# https://update.k3s.io/v1-release/channels
# https://documentation.suse.com/cloudnative/k3s/latest/en/installation/configuration.html
# https://documentation.suse.com/cloudnative/k3s/latest/en/cli/server.html
# https://documentation.suse.com/cloudnative/k3s/latest/en/cli/agent.html

{%- set k3s_auth = salt['pillar.get']('k3s:token') %}
{%- set k3s_channel = salt['pillar.get']('k3s:channel', 'latest') %}
{%- set k3s_host = salt['pillar.get']('k3s:server', 'https://k3s-server:6443') %}
{%- set k3s_role = salt['pillar.get']('k3s:role', 'agent') %}
{%- set k3s_args = salt['pillar.get']('k3s:args', '') %}
{%- if k3s_role == "server" %}
  {%- set k3s_args_extra = "--disable=servicelb --disable=traefik --disable-cloud-controller" ~ " " ~ "--advertise-port=8080" ~ " " ~ "--token=" ~ k3s_auth  %}
  {%- set k3s_service = "k3s.service" %}
  {%- set k3s_uninstall_script = "/usr/local/bin/k3s-uninstall.sh" %}
{%- else %}
  {%- set k3s_args_extra = "--disable-apiserver-lb" ~ " " ~ "--server=" ~ k3s_host ~ " " ~ "--token=" ~ k3s_auth  %}
  {%- set k3s_service = "k3s-agent.service" %}
  {%- set k3s_uninstall_script = "/usr/local/bin/k3s-agent-uninstall.sh" %}
{%- endif %}
{%- set k3s_exec = [k3s_role, k3s_args, k3s_args_extra] | join(' ') | trim %}
{%- set kubeconfig_raw = salt['mine.get']('guava', 'k3s_kubeconfig').get('guava', '') %}
{%- set kubeconfig = kubeconfig_raw | replace('https://127.0.0.1:6443', k3s_host) if kubeconfig_raw else '' %}


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
    - timeout: 90
    - env:
      - INSTALL_K3S_FORCE_RESTART: "true"
      - INSTALL_K3S_SKIP_ENABLE: "true"
      - INSTALL_K3S_SKIP_START: "true"
      - INSTALL_K3S_CHANNEL: "{{ k3s_channel }}"
      - INSTALL_K3S_EXEC: "{{ k3s_exec }}"

k3s_uninstall_script:
  cmd.run:
    - name: {{ k3s_uninstall_script }}
    - onfail:
      - service: k3s_service_start
    - require:
      - cmd: k3s_setup_script

k3s_service_start:
  service.running:
    - name: "{{ k3s_service }}"
    - enable: True
    - require:
      - cmd: k3s_setup_script
    - watch:
      - cmd: k3s_setup_script

{%- if k3s_role != 'server' and kubeconfig %}
k3s_kubeconfig:
  file.managed:
    - name: /etc/rancher/k3s/k3s.yaml
    - contents: {{ kubeconfig | yaml_encode }}
    - mode: '0600'
    - makedirs: True
    - require:
      - service: k3s_service_start
{%- endif %}
