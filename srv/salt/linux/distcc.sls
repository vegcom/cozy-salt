# Distributed compilation server (distccd)
# Gates on host:capabilities:distcc_server
# Requires avahi for zeroconf discovery

{%- set distcc_enabled = salt['pillar.get']('host:capabilities:distcc_server', False) %}
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

# distccd systemd override for zeroconf + custom allow list
distccd_conf:
  file.managed:
    - name: /etc/conf.d/distccd
    - mode: "0644"
    - contents: |
        # Managed by Salt - DO NOT EDIT MANUALLY
        DISTCC_ARGS="--zeroconf --allow {{ distcc_allow | join(' --allow ') }}{%- if distcc_jobs %} --jobs {{ distcc_jobs }}{%- endif %}"
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
