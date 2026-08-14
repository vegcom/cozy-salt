{%- macro cozy_acl(path, group='cozyusers', perms='rwx', onchanges=[], requires=[], bg=True) %}
{%- set os_family = salt['grains.get']('os_family', 'Debian') %}
{%- set state_id = path | replace('/', '_') | replace('.', '_') | replace('\\', '_') | replace(':', '_') %}

{%- if os_family == 'Windows' %}
{%- set icacls_perm = 'F' if perms == 'rwx' else 'RX' %}
{{ state_id }}_acl:
  cmd.run:
    - name: Start-Process -FilePath "icacls.exe" -ArgumentList '"{{ path }}" /grant "{{ group }}:(OI)(CI){{ icacls_perm }}" /t /c /q' -WindowStyle Hidden
    - hide_output: True
    - output_loglevel: quiet
    - order: 10000
    - onlyif: Test-Path "{{ path }}"
    - shell: powershell
  {%- if requires %}
    - require:
    {%- for require in requires %}
      - {{ require | string }}
    {%- endfor %}
  {%- endif %}
  {%- if onchanges %}
    - onchanges:
    {%- for change in onchanges %}
      - {{ change | string }}
    {%- endfor %}
  {%- endif %}
{%- else %}
{{ state_id }}_acl:
  cmd.run:
    - names:
        - setfacl -R -m g:{{ group }}:{{ perms }} {{ path }}
        - setfacl -R -m d:g:{{ group }}:{{ perms }} {{ path }}
  {%- if bg %}
    - bg: True
  {%- else %}
    - hide_output: True
    - output_loglevel: quiet
  {%- endif %}
    - order: 10000
    - onlyif: test -d {{ path }}
  {%- if requires %}
    - require:
    {%- for require in requires %}
      - {{ require | string }}
    {%- endfor %}
  {%- endif %}
  {%- if onchanges %}
    - onchanges:
    {%- for change in onchanges %}
      - {{ change | string }}
    {%- endfor %}
  {%- endif %}
{%- endif %}
{%- endmacro %}
