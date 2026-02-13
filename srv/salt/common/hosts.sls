# Manage /etc/hosts entries for network services (from pillar.network.hosts)
# Cross-platform: host.present works on both Linux and Windows

{% set hosts = salt['pillar.get']('network:hosts', {}) %}

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
