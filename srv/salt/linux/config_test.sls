{%- set dirs = salt['cp.list_master_dirs']() %}
{%- for d in dirs if d.startswith('linux/files/') %}
  {%- set salt_uri = 'salt://' ~ d %}
  {%- set salt_name = d.replace('linux/files/', '') %}
  {%- set path_uri = d.replace('-', '/').replace('linux/files/', '/') %}
{{ salt_name }}_path:
  file.directory:
    - name: {{ path_uri }}
    - user: root
    - group: root
    - mode: "0755"
{{ salt_name }}:
  file.recurse:
    - name: {{ path_uri }}
    - source: {{ salt_uri }}
    - include_empty: True
    - clean: False
    - user: root
    - group: root
    - file_mode: "0755"
    - dir_mode: "0755"
    - recurse:
      - user
      - group
    - require:
      - file: {{ salt_name }}_path
{%- endfor %}
