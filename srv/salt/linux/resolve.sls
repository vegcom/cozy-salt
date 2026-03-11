# Hosts entries managed in common.hosts (cross-platform)
{% set network_config = salt['pillar.get']('network', {}) %}
{% set dns = network_config.get('dns', {}) %}
{% set is_container = salt['file.file_exists']('/.dockerenv') or
                      salt['file.file_exists']('/run/.containerenv') %}

# Configure DNS search domain (skip in containers - they have their own DNS)
{% if not is_container %}
dns_search_domain:
  file.managed:
    - name: /etc/resolv.conf
    - contents: |
        search {{ dns.get('search_domain', 'local') }}
        {% for nameserver in dns.get('nameservers', ['10.0.0.1', '1.1.1.1', '1.0.0.1']) %}
        nameserver {{ nameserver }}
        {% endfor %}
    - mode: "0644"
{% else %}
# DNS configuration skipped - running in container (Docker/Podman/Kubernetes)
skip_dns_config:
  test.nop:
    - name: Skipping resolv.conf management in container environment
{% endif %}
