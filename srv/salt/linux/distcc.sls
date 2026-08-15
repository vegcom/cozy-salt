# Distributed compilation server (distccd) + system-wide client host list
# Server gates on host:capabilities:distcc_server
# zeroconf/avahi discovery does not work over tailscale (no multicast on the
# mesh), so hosts are resolved via headscale.get_distcc_hosts (hostname-prefix
# match) and rendered into /etc/distcc/hosts with a load-factor per host.
# Precedence: $DISTCC_HOSTS env > ~/.distcc/hosts > /etc/distcc/hosts, so this
# file is the system-wide fallback; env/user conf can still override per-host.

# TODO: distcc will be moved to docker, and managed via cozy-salt/provisioning/linux/files/opt-cozy-docker
# TODO: test & report

{%- set distcc_enabled = salt['pillar.get']('host:capabilities:distcc_server', True) %}
{%- set distcc_allow = salt['pillar.get']('distcc:allow', ['127.0.0.1/8', '100.64.0.0/10', '10.0.0.0/24']) %}
{%- set distcc_jobs = salt['pillar.get']('distcc:jobs', None) %}
{%- set is_container = salt['file.file_exists']('/.dockerenv') or salt['file.file_exists']('/run/.containerenv') %}

{%- if distcc_enabled and not is_container %}

distcc_package:
  pkg.installed:
    - name: distcc

distccd_config_path:
  file.directory:
    - name: /etc/conf.d/
    - mode: "0644"

# distccd systemd override, custom allow list (no zeroconf - tailscale has no multicast)
distccd_conf:
  file.managed:
    - name: /etc/conf.d/distccd
    - mode: "0644"
    - contents: |
        # Managed by Salt - DO NOT EDIT MANUALLY
        DISTCC_ARGS="--allow {{ distcc_allow | join(' --allow ') }}{%- if distcc_jobs %} --jobs {{ distcc_jobs }}{%- endif %}"
    - require:
      - pkg: distcc_package

distccd_service:
  service.running:
  {%- if grains['os_family'] == 'Arch' %}
    - name: distccd
  {%- else %}
    - name: distcc
  {%- endif %}
    - enable: True
    - watch:
      - file: distccd_conf

{%- else %}

distcc_server_disabled:
  test.nop:
    - name: distcc server disabled (host:capabilities:distcc_server not set or container)

{%- endif %}

# ============================================================================
# CLIENT: system-wide /etc/distcc/hosts
# ============================================================================
{%- set distcc_client_enabled = salt['pillar.get']('host:capabilities:distcc_client', distcc_enabled) %}
{%- set distcc_prefix = salt['pillar.get']('distcc:hostname_prefix', 'distcc') %}
{%- set distcc_port = salt['pillar.get']('distcc:port', 3632) %}
{%- set distcc_jobs_per_host = salt['pillar.get']('distcc:jobs_per_host', 2) %}
{%- set distcc_include_minions = salt['pillar.get']('distcc:include_minions', True) %}

{%- if distcc_client_enabled and not is_container %}
{%- set distcc_hostnames = salt['headscale.get_distcc_hosts'](prefix=distcc_prefix).split() %}

{#- Fallback tail: every known minion, deduped against real distcc hosts.
    num_cpus comes from the mine (common.mine pillar) so we can tune the load
    factor per host; anything without mine data falls back to the flat
    distcc_jobs_per_host default. #}
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

{%- if distcc_hostnames or minion_entries %}

distcc_hosts_dir:
  file.directory:
    - name: /etc/distcc
    - mode: "0755"

distcc_hosts_file:
  file.managed:
    - name: /etc/distcc/hosts
    - mode: "0644"
    - contents: |
        # Managed by Salt - DO NOT EDIT MANUALLY
        {%- for host in distcc_hostnames %}
        {{ host }}:{{ distcc_port }}/{{ distcc_jobs_per_host }}
        {%- endfor %}
        {%- for entry in minion_entries %}
        {{ entry }}
        {%- endfor %}
    - require:
      - file: distcc_hosts_dir

{%- endif %}
{%- endif %}
