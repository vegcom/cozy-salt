{%- set is_windows = grains['os_family'] == 'Windows' %}
{%- set mine_cids = salt['mine.get']('*', 'ipfs_current_sync_cid') %}
{%- set _self_id = grains.get('id', '') %}
{%- set _IPFS_EMPTY_CID = 'QmUNLLsPACCz1vLxQVkXqqLX5R1X345qqfHbsf67hvA3Nn' %}
{%- set _self_cid_raw = mine_cids.get(_self_id, '') | string | trim %}
{%- set _self_cid = _self_cid_raw if (_self_cid_raw | length >= 32 and ' ' not in _self_cid_raw and _self_cid_raw != _IPFS_EMPTY_CID) else '' %}

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

{%- if _self_cid %}
ipfs_publish_local_identity:
  cmd.run:
    - name: ipfs name publish /ipfs/{{ _self_cid }} --allow-offline
    - env: {{ kubo_env | json }}
{%- if is_windows %}
    - shell: powershell
{%- endif %}
{%- endif %}
