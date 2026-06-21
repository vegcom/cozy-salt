{%- if grains['os_family'] == 'Windows' %}
{%- set master = salt['pillar.get']('salt:master', 'salt') %}
{%- set minion_id = grains['id'] %}

salt_update_download:
  cmd.run:
    - name: >-
        powershell -NonInteractive -ExecutionPolicy Bypass -Command
        "Invoke-WebRequest -Uri https://github.com/saltstack/salt-bootstrap/raw/refs/heads/develop/salt-quick-start.ps1
        -OutFile C:/opt/cozy/cache/salt-quick-start.ps1"

salt_update:
  cmd.run:
    - name: >-
        powershell -NonInteractive -ExecutionPolicy Bypass -Command
        "& C:/opt/cozy/cache/salt-quick-start.ps1 -master {{ master }} -minion-name {{ minion_id }}"
    - require:
      - cmd: salt_update_download
{%- endif %}
