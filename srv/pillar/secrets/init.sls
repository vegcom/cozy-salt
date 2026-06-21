{#- Gate secrets on capabilities. headscale merged into tailscale.sls. #}
{%- set _id = grains.id %}
{%- set _host_file = '/srv/pillar/host/' ~ _id ~ '.sls' %}
{%- set _host = salt['slsutil.renderer'](_host_file, default_renderer='jinja|yaml', ignore_missing=True) or {} %}
{%- set _caps = _host.get('host', {}).get('capabilities', {}) %}

include:
  - secrets.smb
  - secrets.git
  - secrets.mgmt
  - secrets.salt
  - secrets.services
  - secrets.network
  {%- if _caps.get('tailscale') %}
  - secrets.tailscale
  {%- endif %}
  {%- if _caps.get('k3s') %}
  - secrets.k3s
  {%- endif %}
  {%- if _caps.get('kvm') %}
  - secrets.kvm
  {%- endif %}
