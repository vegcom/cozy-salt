# Manage avahi services per host

{%- set is_container = salt['file.file_exists']('/.dockerenv') or salt['file.file_exists']('/run/.containerenv') %}
{%- set avahi_enabled = salt['pillar.get']('host:capabilities:avahi', True) %}
{%- set _id = salt['grains.get']('id') %}
{%- set _desc = salt['pillar.get']('network:hosts', {}).get(_id, {}).get('comment', _id) | string %}
{%- set gw_if = salt['netinfo.default_gw']().get('interface') %}
{%- set tailscale_enabled = salt['pillar.get']('host:capabilities:tailscale', True) %}

{%- if avahi_enabled and is_container == False %}
  {%- if _id %}
avahi_files:
  file.managed:
    - name: /etc/avahi/services/{{ _id }}.service
    - source: salt://_templates/avahi_service.jinja
    - template: jinja
    - description: {{ _desc }}

avahi_config:
  file.managed:
    - name: /etc/avahi/avahi-daemon.conf
    - contents: |
        [server]
        allow-interfaces={{ gw_if }}{%- if tailscale_enabled -%},tailscale0{%- endif -%}
        use-ipv4=yes
        use-ipv6=yes
        ratelimit-interval-usec=1000000
        ratelimit-burst=1000
        [wide-area]
        [publish]
        publish-hinfo=no
        publish-workstation=no
        [reflector]
        enable-reflector=yes
        [rlimits]

avahi_service:
  service.running:
    - name: avahi-daemon
    - enable: True
    - reload:
    - onchanges:
      - file: avahi_config
      - file: avahi_files

include:
  - linux.wsdd

  {%- else %}

avahi_:
  test.nop:
    - name: "not placing.service file"

  {%- endif %}

{%- endif %}
