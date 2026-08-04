{%- set is_windows = grains['os_family'] == 'Windows' %}
{%- set mine_peers = salt['mine.get']('*', 'ipfs_peer_multiaddr') %}
{%- set _self_id = grains.get('id', '') %}

{%- set peering_peers = [] %}
{%- for minion_id, peer_id in mine_peers.items() %}
  {%- set _peer_str = peer_id | string | trim %}
  {%- if minion_id != _self_id and _peer_str and '\n' not in _peer_str and not _peer_str.startswith('Error') %}
    {%- set _id = _peer_str.rsplit('/p2p/', 1)[-1] %}
    {%- do peering_peers.append({'ID': _id, 'Addrs': ['/dns4/' ~ minion_id ~ '/tcp/4001']}) %}
  {%- endif %}
{%- endfor %}

{%- set kubo_env = {
    "GOLOG_LOG_FMT": "nocolor",
    "GOLOG_LOG_LEVEL": "warn",
    "GOLANG_PROTOBUF_REGISTRATION_CONFLICT": "warn",
} %}
{%- set current_path = salt['environ.get']('PATH') %}
{%- if not is_windows %}
  {%- do kubo_env.update({"IPFS_PATH": "/opt/cozy/etc/kubo"}) %}
  {%- do kubo_env.update({"PATH": "/opt/kubo/:" ~ current_path}) %}
{%- else %}
  {%- do kubo_env.update({"IPFS_PATH": "C:/opt/cozy/etc/kubo"}) %}
  {%- do kubo_env.update({"PATH": "C:/opt/kubo/;" ~ current_path}) %}
{%- endif %}

{%- if peering_peers %}
ipfs_configure_peering:
  cmd.run:
    - name: ipfs config --json Peering.Peers
    - args:
      - {{ peering_peers | json }}
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
