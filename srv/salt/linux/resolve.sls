# Hosts entries managed in common.hosts (cross-platform)
{% set network_config = salt['pillar.get']('network', {}) %}
{% set dns = network_config.get('dns', {}) %}
{% set is_container = salt['file.file_exists']('/.dockerenv') or
                      salt['file.file_exists']('/run/.containerenv') %}

# Configure DNS search domain (skip in containers - they have their own DNS)
{% if not is_container %}
resolved_config:
  file.managed:
    - name: /etc/systemd/resolved.conf.d/cozy.conf
    - makedirs: True
    - mode: "0644"
    - contents: |
        [Resolve]
        DNSStubListener=no
        ReadEtcHosts=yes


dns_search_domain:
  file.managed:
    - name: /etc/resolv.conf
    - contents: |
        {%- set search_domains = dns.get('search_domains', dns.get('search_domain', ['local'])) %}
        {%- if search_domains is string %}
        search {{ search_domains }}
        {%- else %}
        search {{ search_domains | join(' ') }}
        {%- endif %}
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
