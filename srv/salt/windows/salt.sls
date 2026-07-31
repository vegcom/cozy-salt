{%- if grains['os_family'] == 'Windows' %}
{%- set master = salt['pillar.get']('salt:master', 'salt') %}
{%- set minion_id = grains['id'] %}

salt_update_download:
  file.managed:
    - name: C:/opt/cozy/cache/salt-quick-start.ps1
    - source: https://github.com/saltstack/salt-bootstrap/raw/refs/heads/develop/salt-quick-start.ps1
    - skip_verify: True
    - mkdirs: True

salt_update:
  cmd.run:
    - name: >-
        powershell -NonInteractive -ExecutionPolicy Bypass -Command
        "& C:/opt/cozy/cache/salt-quick-start.ps1 -master {{ master }} -minion-name {{ minion_id }}"
    - require:
      - file: salt_update_download
{%- endif %}
