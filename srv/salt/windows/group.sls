{%- from '_macros/windows.sls' import get_users_with_profiles with context %}
{%- set managed_users = salt['pillar.get']('managed_users', [], merge=True) %}
{%- set users_with_profiles = get_users_with_profiles().split(',') | reject('equalto', '') | list %}

{%- for user in managed_users %}
{{ user }}_cozyusers_member:
  group.present:
    - name: cozyusers
    - addusers:
      - {{ user }}
    - require:
      - group: cozyusers_group
{%- endfor %}

cozyusers_group:
  group.present:
    - name: cozyusers

{%- for user in managed_users %}
# TODO: move to groups.sls
{{ user }}_cozyusers_member:
  group.present:
    - name: cozyusers
    - addusers:
      - {{ user }}
    - require:
      - group: cozyusers_group
{%- endfor %}
