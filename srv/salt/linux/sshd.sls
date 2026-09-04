{%- set is_container = salt['file.file_exists']('/.dockerenv') or
                      salt['file.file_exists']('/run/.containerenv') %}
{%- set is_ci = _common.get('SALT_CI', False) %}
{%- set ssh_enabled = salt['pillar.get']('host:capabilities:sshd', not is_container, not is_ci) %}

{%- if ssh_enabled %}
include:
  - common.sshd
apply_common_sshd:
  test.nop:
    - require_in:
      - sls: common.sshd
    - context:
        ssh_enabled: {{ ssh_enabled }}
{%- else %}
sshd_service:
  test.nop:
    - name: |
        SSH service disabled:
    {%- if not ssh_enabled %}
        (host:capabilities:sshd = false)
    {%- else %}
        unknown
    {%- endif %}
{%- endif %}
