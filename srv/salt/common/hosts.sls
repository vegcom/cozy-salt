# Manage /etc/hosts entries for network services (from pillar.network.hosts)
# Cross-platform: host.present works on both Linux and Windows

{% set is_container = salt['file.file_exists']('/.dockerenv') or
                      salt['file.file_exists']('/run/.containerenv') %}
{% set hosts = salt['pillar.get']('network:hosts', {}, merge=True) %}

{% if not is_container %}
hosts_entry_localhost:
  host.present:
    - ip:
      - 127.0.0.1
    - names:
      - localhost
      - {{ grains['host'] }}

hosts_entry_localhost6:
  host.present:
    - ip:
      - ::1
    - names:
      - localhost6
      - ip6-localhost
      - ip6-loopback
{% endif %}

{% for id, entry in hosts.items() %}
hosts_entry_{{ id | replace('-', '_') | replace('.', '_') }}:
  host.present:
    - ip:
    {%- for ip in entry.get('ips', []) %}
      - {{ ip }}
    {%- endfor %}
    - names:
    {%- for name in entry.get('names', []) %}
      - {{ name }}
    {%- endfor %}
{%- if entry.get('comment') %}
    - comment: {{ entry['comment'] }}
{%- endif %}
    - clean: True
{% endfor %}
