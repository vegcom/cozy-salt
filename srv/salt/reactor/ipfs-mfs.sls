{%- set minion_id = data['id'] %}
ipfs_mfs_{{ minion_id }}:
  local.state.apply:
    - tgt: 'host:capabilities:ipfs:true'
    - tgt_type: pillar
    - arg:
      - common.ipfs.sync
