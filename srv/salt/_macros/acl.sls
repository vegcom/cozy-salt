{%- macro cozy_acl(path, group='cozyusers', perms='rwx') %}
{%- set os_family = salt['grains.get']('os_family', 'Debian') %}
{%- set state_id = path | replace('/', '_') | replace('.', '_') | replace('\\', '_') | replace(':', '_') %}

{%- if os_family == 'Windows' %}
{%- set icacls_perm = 'F' if perms == 'rwx' else 'RX' %}
{{ state_id }}_acl:
  cmd.run:
    - name: icacls "{{ path }}" /grant "{{ group }}:(OI)(CI){{ icacls_perm }}" /t /c /q
    - onlyif: Test-Path "{{ path }}"
    - shell: powershell

{%- else %}
{{ state_id }}_acl:
  cmd.run:
    - name: |
        setfacl -R -m g:{{ group }}:{{ perms }} {{ path }}
        setfacl -R -m d:g:{{ group }}:{{ perms }} {{ path }}
    - onlyif: test -d {{ path }}
    - unless: getfacl {{ path }} 2>/dev/null | grep -q "group:{{ group }}:{{ perms }}"

{%- endif %}
{%- endmacro %}
