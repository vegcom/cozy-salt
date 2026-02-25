# macvlan-shim: persistent macvlan shim interface for Docker host-to-container routing
# Required on Docker hosts using macvlan networks (host cannot reach macvlan IPs directly)
# See provisioning docs and cozy-share/README.md for context

{%- set shim = salt['pillar.get']('macvlan_shim', {}) %}

{%- if shim %}
{%- set shim_name = shim.get('shim_name', 'frontend-shim') %}
{%- set parent = shim.get('parent', 'eth0') %}
{%- set shim_ip = shim.get('shim_ip') %}
{%- set routes = shim.get('routes', []) %}

macvlan_shim_service_file:
  file.managed:
    - name: /etc/systemd/system/macvlan-shim.service
    - source: salt://_templates/macvlan-shim.jinja
    - template: jinja
    - mode: "0644"
    - shim_name: {{ shim_name }}
    - parent: {{ parent }}
    - shim_ip: {{ shim_ip }}
    - routes: {{ routes | tojson }}

macvlan_shim_service:
  service.running:
    - name: macvlan-shim
    - enable: True
    - require:
      - file: macvlan_shim_service_file
    - watch:
      - file: macvlan_shim_service_file

{%- else %}

macvlan_shim_noop:
  test.nop:
    - name: macvlan_shim pillar not set, skipping

{%- endif %}
