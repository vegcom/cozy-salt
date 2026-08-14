# K3S installation via
# https://raw.githubusercontent.com/k3s-io/k3s/main/install.sh
# https://update.k3s.io/v1-release/channels
# https://documentation.suse.com/cloudnative/k3s/latest/en/installation/configuration.html
# https://documentation.suse.com/cloudnative/k3s/latest/en/cli/server.html
# https://documentation.suse.com/cloudnative/k3s/latest/en/cli/agent.html
#
# https://docs.k3s.io/cli/agent
# /etc/rancher/k3s/registries.yaml

{%- set k3s_enabled = salt['pillar.get']('host:capabilities:k3s', False) %}
{%- if not k3s_enabled %}
k3s_not_enabled:
  test.nop:
    - name: Skipping k3s
{%- else %}
  {%- set k3s_data_dir = salt['pillar.get']('k3s:data_dir', '/var/lib/rancher/k3s') %}
  {%- set k3s_auth = salt['pillar.get']('k3s:token') %}
  {%- set k3s_channel = salt['pillar.get']('k3s:channel', 'latest') %}
  {%- set k3s_server = salt['pillar.get']('k3s:server', 'https://k3s-server:6443') %}
  {%- set k3s_role = salt['pillar.get']('k3s:role', 'agent') %}
  {%- set k3s_kwargs = salt['pillar.get']('k3s:kwargs', '') %}
  {%- set k3s_kwargs_opt = salt['pillar.get']('k3s:kwargs_opt', '') %}
  {%- set k3s_host = salt['pillar.get']('k3s:host', 'localhost') %}
  {%- set k3s_port = salt['pillar.get']('k3s:port', '6443') %}
  {%- set _ts_ips = salt['grains.get']('ip4_interfaces:tailscale0', []) %}
  {%- set k3s_advertise_address = _ts_ips[0] if _ts_ips else none %}
  {%- set k3s_flannel_iface = salt['pillar.get']('k3s:flannel_iface') or salt['netinfo.default_gw']().get('interface') %}
  {%- if k3s_role in ["server", "loadbalancer"] %}
    {%- set k3s_args = "server" %}
    {%- set k3s_service = "k3s.service" %}
    {%- set k3s_uninstall_script = "/usr/local/bin/k3s-uninstall.sh" %}
  {%- else %}
    {%- set k3s_args = "agent" %}
    {%- set k3s_service = "k3s-agent.service" %}
    {%- set k3s_uninstall_script = "/usr/local/bin/k3s-agent-uninstall.sh" %}
  {%- endif %}
  {%- set k3s_node_token = salt['mine.get'](k3s_host, 'k3s_node_token').get(k3s_host, k3s_auth) | trim %}
  {%- set k3s_auth_resolved = k3s_node_token if k3s_node_token else k3s_auth %}
  {%- set k3s_bootstrap = salt['pillar.get']('k3s:bootstrap', False) %}
  {%- if k3s_role == "server" %}
    {%- if k3s_bootstrap %}
    {%- set k3s_kwargs_extra = "--cluster-init --secrets-encryption --prefer-bundled-bin --disable=servicelb --disable=traefik --disable-cloud-controller --flannel-backend=host-gw --advertise-address=" ~ k3s_advertise_address ~ " --advertise-port=" ~ k3s_port ~ " " ~ "--token=" ~ k3s_auth_resolved %}
    {%- else %}
    {%- set k3s_kwargs_extra = "--secrets-encryption --prefer-bundled-bin --disable=servicelb --disable=traefik --disable-cloud-controller --flannel-backend=host-gw  --advertise-address=" ~ k3s_advertise_address ~ " --advertise-port=" ~ k3s_port ~ " " ~ "--token=" ~ k3s_auth_resolved %}
    {%- endif %}
  {%- elif k3s_role == "loadbalancer" %}
    {%- set k3s_kwargs_extra = "--secrets-encryption --prefer-bundled-bin --disable=servicelb --disable=traefik --disable-cloud-controller --flannel-backend=host-gw" ~ " " ~ "--server=" ~ k3s_server ~ " " ~ "--advertise-address=" ~ k3s_advertise_address ~ " " ~ "--advertise-port=" ~ k3s_port ~ " " ~ "--token=" ~ k3s_auth_resolved %}
  {%- else %}

    {%- set k3s_kwargs_extra = "--prefer-bundled-bin --disable-apiserver-lb" ~ " " ~ "--server=" ~ k3s_server ~ " " ~ "--token=" ~ k3s_auth_resolved %}
  {%- endif %}
  {%- set embedded_registry = "--embedded-registry --disable-cloud-controller" if salt["pillar.get"]("k3s.embedded_registry") else " " %}
  {%- set k3s_exec = [k3s_args, k3s_kwargs, k3s_kwargs_opt, k3s_kwargs_extra, embedded_registry] | join(' ') | trim %}
  {%- set kubeconfig_raw = salt['mine.get'](k3s_host, 'k3s_kubeconfig').get(k3s_host, '') %}
  {%- if kubeconfig_raw %}
    {%- set needle = 'https://127.0.0.1:' ~ (k3s_port | string) %}
    {%- set kubeconfig = kubeconfig_raw | replace(needle, k3s_server | string) %}
  {%- else %}
    {%- set kubeconfig = '' %}
  {%- endif %}

k3s_env_config:
  file.managed:
    - name: /etc/environment.d/cozy-k3s.conf
    - contents: |
        K3S_DATA_DIR={{ k3s_data_dir }}
    - mode: '0640'
    - makedirs: True

k3s_download_script:
  file.managed:
    - name: /tmp/k3s-init.sh
    - order: 0
    - source: https://raw.githubusercontent.com/k3s-io/k3s/main/install.sh
    - source_hash: https://raw.githubusercontent.com/k3s-io/k3s/main/install.sh.sha256sum
    - mode: "0750"

k3s_setup_script:
  cmd.run:
    - name: bash /tmp/k3s-init.sh
    - order: 1
    - require:
      - file: k3s_download_script
    - timeout: 300
    - hide_output: True
    - output_loglevel: quiet
    - env:
      - K3S_KUBECONFIG_MODE: "600"
      - K3S_KUBECONFIG_GROUP: "cozyusers"
      - INSTALL_K3S_CHANNEL: "{{ k3s_channel }}"
      - INSTALL_K3S_EXEC: "{{ k3s_exec }}"

k3s_uninstall_script:
  cmd.run:
    - name: {{ k3s_uninstall_script }}
    - order: 99
    - env:
      - K3S_DATA_DIR: {{ k3s_data_dir }}
    - onfail:
      - service: k3s_service_start

k3s_service_start:
  service.running:
    - name: "{{ k3s_service }}"
    - order: 2
    - enable: True
    - no_block: True
    - require:
      - cmd: k3s_setup_script
    - watch:
      - cmd: k3s_setup_script

k3s_kubeconfig:
  file.managed:
    - name: /etc/rancher/k3s/k3s.yaml
    - order: 3
    - contents: {{ kubeconfig | yaml_encode }}
    - mode: '0640'
    - group: cozyusers
    - makedirs: True
    - show_changes: False
    - require:
      - service: k3s_service_start
{%- endif %}
