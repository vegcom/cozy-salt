{%- set is_windows = grains['os_family'] == 'Windows' %}
{%- set mine_keys = salt['mine.get']('*', 'ipfs_private_swarm_key') %}

{%- set _ts_iface = 'Tailscale' if is_windows else 'tailscale0' %}
{%- set _ts_ips = salt['grains.get']('ip4_interfaces', {}).get(_ts_iface, []) %}
{%- set vpn_ip = _ts_ips[0] if _ts_ips else none %}

{%- set gw = salt['netinfo.default_gw']() %}
{%- set iface = gw.get('interface', '') %}
{%- set _iface_ips = salt['grains.get']('ip4_interfaces', {}).get(iface, []) %}
{%- set lan_ip = _iface_ips[0] if _iface_ips else none %}

{%- set gateway_port = salt[pillar.get]('ipfs.config.gateway_port', '3696') %}
{%- set api_port = salt[pillar.get]('``.api_port', '5001') %}

{%- set kubo_env = {
    "GOLOG_LOG_FMT": "nocolor",
    "GOLOG_LOG_LEVEL": "warn",
    "GOLANG_PROTOBUF_REGISTRATION_CONFLICT": "warn",
} %}

{%- set current_path = salt['environ.get']('PATH') %}

{%- if not is_windows %}
  {%- do kubo_env.update({"IPFS_PATH": "/opt/cozy/etc/kubo"}) %}
{%- else %}
  {%- do kubo_env.update({"IPFS_PATH": "C:/opt/cozy/etc/kubo"}) %}
{%- endif %}

ipfs_config_path:
  file.directory:
{%- if is_windows %}
    - name: C:/opt/cozy/etc/kubo
{%- else %}
    - name: /opt/cozy/etc/kubo
{%- endif %}
    - mkdirs: True
{%- if is_windows %}
    - win_owner: 'Administrators'
    - win_perms:
        cozyusers:
          perms: full_control
{%- else %}
    - user: cozy-salt-svc
    - group: cozyusers
    - mode: '0770'
    - file_mode: '0660'
    - dir_mode: '0770'
    - recurse:
      - user
      - group
      - mode
{%- endif %}

{%- for key, value in kubo_env.items() %}
kubo_env_{{ key | lower }}:
  environ.setenv:
    - name: {{ key }}
    - value: {{ value }}
    - update_minion: True
  {%- if is_windows %}
    - permanent: HKLM
  {%- endif %}
{%- endfor %}

{%- if not is_windows %}
  {%- do kubo_env.update({"PATH": "/opt/kubo/:" ~ current_path}) %}
{%- else %}
  {%- do kubo_env.update({"PATH": "C:/opt/kubo/;" ~ current_path}) %}
{%- endif %}

ipfs_init:
  cmd.run:
    - name: ipfs init
    - env: {{ kubo_env | json }}
{%- if is_windows %}
    - shell: powershell
{%- endif %}
    - success_retcodes:
      - 0
      - 1
    - require:
      - file: ipfs_config_path

{%- set _swarm_addrs = ['/ip4/127.0.0.1/tcp/4001'] %}
{%- if vpn_ip %}
  {%- do _swarm_addrs.append('/ip4/' ~ vpn_ip ~ '/tcp/4001') %}
  {%- do _swarm_addrs.append('/ip4/' ~ vpn_ip ~ '/udp/4001/quic-v1') %}
{%- endif %}
{%- if lan_ip %}
  {%- do _swarm_addrs.append('/ip4/' ~ lan_ip ~ '/tcp/4001') %}
  {%- do _swarm_addrs.append('/ip4/' ~ lan_ip ~ '/udp/4001/quic-v1') %}
{%- endif %}

ipfs_configure_private_networking:
  cmd.run:
    - names:
      - ipfs bootstrap rm --all
      - ipfs config Addresses.Swarm --json '{{ _swarm_addrs | tojson }}'
      - ipfs config Addresses.API "/ip4/127.0.0.1/tcp/{{ api_port }}"
      - ipfs config Addresses.Gateway "/ip4/127.0.0.1/tcp/{{ gateway_port }}"
      - ipfs config Routing.Type "dhtclient"
      - ipfs config --json Reprovider null
      - ipfs config --json Swarm.AddrFilters '[]'
      - ipfs config --json Routing.DelegatedRouters '[]'
      - ipfs config --json Ipns.DelegatedPublishers '[]'
      - ipfs config --json DNS.Resolvers '{}'
      - ipfs config --bool Discovery.MDNS.Enabled true
      - ipfs config --bool Ipns.UsePubsub true
      - ipfs config --bool Swarm.Transports.Network.Websocket false
      - ipfs config --bool AutoConf.Enabled false
    - env: {{ kubo_env | json }}
{%- if is_windows %}
    - shell: powershell
{%- endif %}

{%- if not is_windows %}
ipfs_service:
  service.running:
    - name: ipfs
    - enable: True
    - reload: True
    - no_block: True
    - require:
      - cmd: ipfs_configure_private_networking
{%- endif %}

ipfs_swarm_key:
  file.managed:
{%- if is_windows %}
    - name: C:/opt/cozy/etc/kubo/swarm.key
{%- else %}
    - name: /opt/cozy/etc/kubo/swarm.key
{%- endif %}
{%- if mine_keys %}
    - contents: |-
        {{ mine_keys.values() | first | indent(8) }}
{%- else %}
    - source:  salt://_templates/swarm.key.jinja
    - template: jinja
{%- endif %}
    - replace: False
{%- if not is_windows %}
    - user: cozy-salt-svc
    - group: cozyusers
    - mode: '0660'
{%- endif %}
    - mkdirs: True
    - require:
      - file: ipfs_config_path

{%- if not is_windows %}
ipfs_config_path_perms:
  file.directory:
    - name: /opt/cozy/etc/kubo
    - user: cozy-salt-svc
    - group: cozyusers
    - dir_mode: '0770'
    - file_mode: '0660'
    - recurse:
      - user
      - group
      - mode
    - require:
      - cmd: ipfs_configure_private_networking
      - file: ipfs_swarm_key
{%- endif %}
