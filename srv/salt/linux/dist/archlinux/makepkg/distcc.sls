# ============================================================================
# MAKEPKG CONFIGURATION - DISTCC_HOSTS
# ----------------------------------------------------------------------------

{%- set distcc_enabled = salt['pillar.get']('host:capabilities:distcc_server', True) %}
{%- set is_container = salt['file.file_exists']('/.dockerenv') or salt['file.file_exists']('/run/.containerenv') %}
{%- set distcc_client_enabled = salt['pillar.get']('host:capabilities:distcc_client', distcc_enabled) %}
{%- set distcc_prefix = salt['pillar.get']('distcc:hostname_prefix', 'distcc') %}
{%- set distcc_port = salt['pillar.get']('distcc:port', 3632) %}
{%- set distcc_jobs_per_host = salt['pillar.get']('distcc:jobs_per_host', 2) %}
{%- set distcc_include_minions = salt['pillar.get']('distcc:include_minions', True) %}
{%- if distcc_client_enabled and not is_container %}
{%- set distcc_hosts = [] %}
  {%- set distcc_hostnames = salt['headscale.get_distcc_hosts'](prefix=distcc_prefix).split() %}
  {%- set minion_entries = [] %}
  {%- if distcc_include_minions %}
      {%- set minion_ids = salt['mine.get']('*', 'id').keys() | list %}
      {%- set minion_cpus = salt['mine.get']('*', 'num_cpus') %}
      {%- for minion_id in minion_ids | sort %}
        {%- if minion_id not in distcc_hostnames %}
          {%- set cpus = minion_cpus.get(minion_id) %}
          {%- set jobs = ((cpus // 2) | int) if cpus and cpus > 1 else distcc_jobs_per_host %}
          {%- do minion_entries.append(minion_id ~ ':' ~ distcc_port ~ '/' ~ jobs) %}
        {%- endif %}
      {%- endfor %}
    {%- endif %}
{%- endif %}
{%- if distcc_hostnames or minion_entries %}
  {%- for host in minion_entries %}
    {%- do distcc_hosts.append(host) %}
  {%- endfor %}
  {%- for host in distcc_hostnames %}
    {%- do distcc_hosts.append(host ~ ':' ~ distcc_port ~ '/' ~ distcc_jobs_per_host) %}
  {%- endfor %}
{%- endif %}

makepkg_distcc_conf:
  file.managed:
    - name: /etc/makepkg.conf.d/cozy-distcc.conf
    - mode: "0644"
    - user: root
    - group: root
    - contents: |
        #!/hint/bash
        # Managed by cozy-salt - DO NOT EDIT MANUALLY
{%- if distcc_hosts %}
        DISTCC_HOSTS="{{ distcc_hosts|join(' ') }}"
{%- endif %}

makepkg_environment.d_conf:
  file.managed:
    - name: /etc/environment.d/cozy-distcc.conf
    - mode: "0644"
    - user: root
    - group: root
    - contents: |
        # Managed by cozy-salt - DO NOT EDIT MANUALLY
{%- if distcc_hosts %}
        DISTCC_HOSTS="{{ distcc_hosts|join(' ') }}"
{%- endif %}
