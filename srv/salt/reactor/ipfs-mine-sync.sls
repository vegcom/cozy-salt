{# Fire on salt/minion/*/start — refresh mine data only, network change beacon drives sync #}
{%- set minion_id = data['id'] %}

ipfs_mine_update_{{ minion_id }}:
  local.module.run:
    - tgt: {{ minion_id }}
    - arg:
      - mine.update
