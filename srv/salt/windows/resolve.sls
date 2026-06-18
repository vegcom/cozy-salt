# Windows DNS search domain configuration
{% set network_config = salt['pillar.get']('network', {}) %}
{% set dns = network_config.get('dns', {}) %}
{%- set search_domains = dns.get('search_domains', dns.get('search_domain', ['local'])) %}
{%- if search_domains is string %}
  {%- set search_domains = [search_domains] %}
{%- endif %}

dns_search_domains:
  cmd.run:
    - name: |
        Set-DnsClientGlobalSetting -SuffixSearchList @({{ search_domains | map('tojson') | join(', ') }})
    - shell: powershell
    - unless: |
        $current = (Get-DnsClientGlobalSetting).SuffixSearchList
        $wanted = @({{ search_domains | map('tojson') | join(', ') }})
        if ($current.Count -ne $wanted.Count) { exit 1 }
        for ($i=0; $i -lt $current.Count; $i++) { if ($current[$i] -ne $wanted[$i]) { exit 1 } }
        exit 0
