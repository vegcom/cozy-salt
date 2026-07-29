{%- set is_container = salt['file.file_exists']('/.dockerenv') or
                      salt['file.file_exists']('/run/.containerenv') %}
{%- set is_ci = salt['pillar.get']('SALT_CI', False) %}

{%- if is_container or is_ci %}

ipfs_skip:
  test.nop:
    - name: "no ipfs in containeres"

{%- else %}

{%- set is_windows = grains['os_family'] == 'Windows' %}
{%- set mine_keys = salt['mine.get']('*', 'ipfs_private_swarm_key') %}
{%- set mine_peers = salt['mine.get']('*', 'ipfs_peer_multiaddr') %}
{%- set mine_cids = salt['mine.get']('*', 'ipfs_current_sync_cid') %}
{%- set _self_id = grains.get('id', '') %}
{%- set _IPFS_EMPTY_CID = 'QmUNLLsPACCz1vLxQVkXqqLX5R1X345qqfHbsf67hvA3Nn' %}
{%- set peering_peers = [] %}
{%- for minion_id, peer_id in mine_peers.items() %}
  {%- set _peer_str = peer_id | string | trim %}
  {%- if minion_id != _self_id and _peer_str and '\n' not in _peer_str and not _peer_str.startswith('Error') %}
    {%- set _id = _peer_str.rsplit('/p2p/', 1)[-1] %}
    {%- do peering_peers.append({'ID': _id, 'Addrs': ['/dns4/' ~ minion_id ~ '/tcp/4001']}) %}
  {%- endif %}
{%- endfor %}

{%- set _ts_iface = 'Tailscale' if is_windows else 'tailscale0' %}
{%- set _ts_ips = salt['grains.get']('ip4_interfaces', {}).get(_ts_iface, []) %}
{%- set vpn_ip = _ts_ips[0] if _ts_ips else none %}

{%- set gw = salt['netinfo.default_gw']() %}
{%- set iface = gw.get('interface', '') %}
{%- set lan_ip = salt['grains.get']('ip4_interfaces', {}).get(iface, [''])[0] %}

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

{%- set ipfs_requires = [{'file': 'ipfs_config_path'}] %}
{%- for key, value in kubo_env.items() %}
  {%- do ipfs_requires.append({'environ': 'kubo_env_' ~ key | lower}) %}
{%- endfor %}

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
      - ipfs config Addresses.API "/ip4/127.0.0.1/tcp/5001"
      - ipfs config Addresses.Gateway "/ip4/127.0.0.1/tcp/8080"
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

share_swarm_key_to_mine:
  module.run:
    - mine.send:
      - name: ipfs_private_swarm_key
      - mine_function: file.read
{%- if is_windows %}
      - path: C:/opt/cozy/etc/kubo/swarm.key
{%- else %}
      - path: /opt/cozy/etc/kubo/swarm.key
{%- endif %}

share_peer_addr_to_mine:
  module.run:
    - mine.send:
      - name: ipfs_peer_multiaddr
      - mine_function: cmd.run
      - cmd: ipfs config Identity.PeerID

share_sync_cid_to_mine:
  module.run:
    - mine.send:
      - name: ipfs_current_sync_cid
      - mine_function: cmd.run
      - cmd: ipfs files stat --hash /

share_mfs_paths_to_mine:
  module.run:
    - mine.send:
      - name: ipfs_mfs_paths
      - mine_function: cmd.run
      - cmd: ipfs files ls -l /

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
  {%- set _self_cid = mine_cids.get(_self_id, '') | string | trim %}
  {%- if _self_cid and (_self_cid.startswith('Qm') or _self_cid.startswith('baf')) %}
      - cmd: ipfs_publish_local_identity
  {%- endif %}
{%- endif %}

{%- if peering_peers %}
ipfs_configure_peering:
  cmd.run:
    - name: ipfs config --json Peering.Peers '{{ peering_peers | json }}'
    - env: {{ kubo_env | json }}
{%- if is_windows %}
    - shell: powershell
{%- endif %}

ipfs_bootstrap_peers:
  cmd.run:
    - names:
{%- for peer in peering_peers %}
      - ipfs bootstrap add /dns4/{{ peer.Addrs[0].split('/dns4/')[1].split('/tcp/')[0] }}/tcp/4001/p2p/{{ peer.ID }}
{%- endfor %}
    - env: {{ kubo_env | json }}
{%- if is_windows %}
    - shell: powershell
{%- endif %}
{%- endif %}

{%- set _self_cid = mine_cids.get(_self_id, '') | string | trim %}
{%- if _self_cid and (_self_cid.startswith('Qm') or _self_cid.startswith('baf')) %}
ipfs_publish_local_identity:
  cmd.run:
    - name: ipfs name publish /ipfs/{{ _self_cid }}  --allow-offline
    - env: {{ kubo_env | json }}
{%- if is_windows %}
    - shell: powershell
{%- endif %}
{%- endif %}

{%- set _peers_to_pin = [] %}
{%- for minion_id, cid in mine_cids.items() %}
  {%- set _cid_str = cid | string | trim %}
  {%- if minion_id != _self_id and _cid_str and _cid_str != _IPFS_EMPTY_CID and (_cid_str | length >= 32 and ' ' not in _cid_str) %}
    {%- set _raw = mine_peers.get(minion_id, '') | string | trim %}
    {%- if _raw and '\n' not in _raw and not _raw.startswith('Error') %}
      {%- do _peers_to_pin.append(_raw.rsplit('/p2p/', 1)[-1]) %}
    {%- endif %}
  {%- endif %}
{%- endfor %}

{#
  MFS sync: peers' /path → CID mappings come from mine (ipfs_mfs_paths).
  This state copies any MFS paths from peers that don't exist locally yet.

  NEW HOST BOOTSTRAP: on a fresh node, manually seed content into MFS first:
    ipfs files cp /ipfs/<root-cid> /<path>
  e.g.: ipfs files cp /ipfs/QmYBoexv... /git
  After that, highstate handles all future sync automatically.
#}
{%- set mine_mfs = salt['mine.get']('*', 'ipfs_mfs_paths') %}
{%- set _mfs_cp_cmds = [] %}
{%- set _mfs_seen_paths = [] %}
{%- for minion_id, ls_output in mine_mfs.items() %}
  {%- set _ls_str = ls_output | string | trim %}
  {%- if minion_id != _self_id and _ls_str and 'Error' not in _ls_str %}
    {%- for line in _ls_str.split('\n') %}
      {%- set parts = line.split() %}
      {%- if parts | length >= 3 and parts[1] | length >= 32 and ' ' not in parts[1] and parts[1] != _IPFS_EMPTY_CID %}
        {%- set path_name = parts[0].rstrip('/') %}
        {%- if path_name not in _mfs_seen_paths %}
          {%- do _mfs_seen_paths.append(path_name) %}
          {%- do _mfs_cp_cmds.append({'cmd': 'ipfs files cp /ipfs/' ~ parts[1] ~ ' /' ~ path_name, 'unless': 'ipfs files stat /' ~ path_name}) %}
        {%- endif %}
      {%- endif %}
    {%- endfor %}
  {%- endif %}
{%- endfor %}

{%- for entry in _mfs_cp_cmds %}
ipfs_sync_mfs_{{ entry.cmd | md5 }}:
  cmd.run:
    - name: {{ entry.cmd }}
    - unless: {{ entry.unless }}
    - env: {{ kubo_env | json }}
{%- if is_windows %}
    - shell: powershell
{%- endif %}
    - success_retcodes:
      - 0
      - 1
{%- endfor %}

{%- if _peers_to_pin %}
ipfs_sync_private_cluster_pins:
  cmd.run:
    - names:
{%- for peer_id in _peers_to_pin %}
      - ipfs pin add /ipns/{{ peer_id }} --timeout 30s
{%- endfor %}
    - env: {{ kubo_env | json }}
    - success_retcodes:
      - 0
      - 1
{%- if is_windows %}
    - shell: powershell
{%- endif %}
{%- endif %}
{%- endif %}
