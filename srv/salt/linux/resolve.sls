# Hosts entries managed in common.hosts (cross-platform)
{%- set network_config = salt['pillar.get']('network', {}) %}
{%- set dns = network_config.get('dns', {}) %}
{%- set is_container = salt['file.file_exists']('/.dockerenv') or
                      salt['file.file_exists']('/run/.containerenv') %}

# Configure DNS search domain (skip in containers - they have their own DNS)
{%- if not is_container %}
resolved_config:
  file.managed:
    - name: /etc/systemd/resolved.conf.d/cozy.conf
    - makedirs: True
    - mode: "0644"
    - contents: |
        [Resolve]
        DNSStubListener=no
        ReadEtcHosts=yes
        MulticastDNS=no

resolved_restart:
  service.running:
    - enable: True
    - reload: True
    - onchanges:
      - file: resolved_config

{%- for file in ["/etc/resolv.conf", "/etc/resolvconf/resolv.conf.d/tail"] %}
dns_search_domain{{ file.replace("/", "_").replace(".", "_") }}:
  file.managed:
    - name: {{ file }}
    - makedirs: True
    - contents: |
        {%- set search_domains = dns.get('search_domains', dns.get('search_domain', ['local'])) %}
        {%- if search_domains is string %}
        search {{ search_domains }}
        {%- else %}
        search {{ search_domains | join(' ') }}
        {%- endif %}
        {%- for nameserver in dns.get('nameservers', ['10.0.0.1', '1.1.1.1', '1.0.0.1']) %}
        nameserver {{ nameserver }}
        {%- endfor %}
    - mode: "0644"
    - unless: test -L {{ file }} || lsattr {{ file }} 2>/dev/null | grep -q -- '-i-'
{%- endfor %}

{%- else %}
# DNS configuration skipped - running in container (Docker/Podman/Kubernetes)
skip_dns_config:
  test.nop:
    - name: Skipping resolv.conf management in container environment
{%- endif %}
