# Manage avahi services per host
# https://tailscale.com/api

{% set is_container = salt['file.file_exists']('/.dockerenv') or salt['file.file_exists']('/run/.containerenv') %}

{%- set avahi_enabled = salt['pillar.get']('host:capabilities:avahi', True) %}
{%- set _id = salt['grains.get']('id') %}
{%- set _desc = salt['pillar.get']('network:hosts', {}).get(_id, {}).get('comment', _id) | string %}


{%-  if avahi_enabled and is_container == False %}
  {%- if _id %}
avahi_files:
  file.managed:
    - name: /etc/avahi/services/{{ _id }}.service
    - source: salt://_templates/avahi_service.jinja
    - template: jinja
    - description: {{ _desc }}

include:
  - linux.wsdd

  {%- else %}
avahi_:
  test.nop:
    - name: "not placing.service fle"
  {%- endif %}
avahi_enable:
  service.running:
    - name: avahi-daemon
    - enable: True
{%- endif %}
