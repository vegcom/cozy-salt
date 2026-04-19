{%- if grains['os_family'] != 'Windows' %}
{%- set master = salt['pillar.get']('salt:master', 'salt') %}
{%- set version = salt['pillar.get']('salt:version', 'latest') %}
{%- set minion_id = grains['id'] %}

salt_update:
  cmd.run:
    - name: >-
        curl -L https://raw.githubusercontent.com/saltstack/salt-bootstrap/develop/bootstrap-salt.sh
        | sh -s -- -A {{ master }} -i {{ minion_id }} onedir {{ version }}
    - shell: /bin/bash
{%- endif %}
