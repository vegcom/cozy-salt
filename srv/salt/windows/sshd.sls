{%- set ssh_enabled = salt['pillar.get']('host:capabilities:sshd', True) %}
{%- set paths = salt['pillar.get']('paths', {}) %}
{%- set pwsh_7_profile = paths.get('powershell_7_profile', 'C:/Program Files/PowerShell/7') %}
{%- set pwsh_exe = pwsh_7_profile + "/pwsh.exe" %}
{%- set pwsh_present = salt['file.file_exists'](pwsh_exe) %}

{%- if pwsh_present and ssh_enabled %}
openssh_default_shell:
  reg.present:
    - name: HKLM\SOFTWARE\OpenSSH
    - vname: DefaultShell
    - vdata: {{ pwsh_exe }}
    - vtype: REG_SZ
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
  {%- elif not pwsh_present %}
        FileNotFound: "{{ pwsh_exe }}"
  {%- else %}
    unknown
  {%- endif %}
{%- endif %}
