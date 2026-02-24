{%- set salt_master = salt['pillar.get']('salt:master', '') %}
{%- set k3s_enabled = salt['pillar.get']('host:capabilities:k3s', False) %}
{%- set k3s_role = salt['pillar.get']('k3s:role', 'agent') %}

{%- set minion_conf = "master: " ~ salt_master ~ "\n" %}
{%- if k3s_enabled and k3s_role == 'server' %}
  {%- set minion_conf = minion_conf ~ "mine_functions:\n  k3s_kubeconfig:\n    - mine_function: file.read\n    - /etc/rancher/k3s/k3s.yaml\n" %}
{%- endif %}

salt_minion_conf:
  file.managed:
    - name: /etc/salt/minion.d/99-cozy.conf
    - mode: '0644'
    - contents: {{ minion_conf | yaml_encode }}

# NOTE: restarting salt-minion during salt-call interrupts the run
# apply this state via master: salt '*' state.sls linux.salt_minion
salt_minion_service:
  service.running:
    - name: salt-minion
    - enable: True
    - watch:
      - file: salt_minion_conf
