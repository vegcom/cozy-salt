{%- set minion_id = data['id'] %}
ipfs_publish_{{ minion_id }}:
  local.state.apply:
    - tgt: {{ minion_id }}
    - arg:
      - common.ipfs.publish
