{%- set is_windows = grains['os_family'] == 'Windows' %}
{%- set mine_cids = salt['mine.get']('*', 'ipfs_current_sync_cid') %}
{%- set mine_peers = salt['mine.get']('*', 'ipfs_peer_multiaddr') %}
{%- set mine_mfs = salt['mine.get']('*', 'ipfs_mfs_paths') %}
{%- set _self_id = grains.get('id', '') %}
{%- set _IPFS_EMPTY_CID = 'QmUNLLsPACCz1vLxQVkXqqLX5R1X345qqfHbsf67hvA3Nn' %}

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
