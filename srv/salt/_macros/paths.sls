{%- macro managed_tree(name, source, user='root', group='root',
                       dir_mode='0755', file_mode='0644',
                       clean=False, require=None, order=None, recurse=False, mkdirs=True) %}

{%- set state_name = name.replace('/', '_') %}
{%- set state_name = state_name[1:] if state_name.startswith('_') else state_name %}

{#- manage path #}
{{ state_name }}_dir:
  file.directory:
    - name: {{ name }}
    - user: {{ user }}
    - group: {{ group }}
    - mode: "{{ dir_mode }}"
    - mkdirs: {{ mkdirs }}
    {%- if require %}
    - require:
      - {{ require }}
    {%- endif %}
    {%- if order is not none %}
    - order: {{ order }}
    {%- endif %}

{# recursively place files #}
{{ state_name }}_files:
  file.recurse:
    - name: {{ name }}
    - source: {{ source }}
    - include_empty: True
    - clean: {{ clean }}
    - user: {{ user }}
    - group: {{ group }}
    - file_mode: "{{ file_mode }}"
    - dir_mode: "{{ dir_mode }}"
{%- if recurse %}
    - recurse:
      - user
      - group
{%- endif %}
    - require:
      - file: {{ state_name }}_dir
    {%- if order is not none %}
    - order: {{ order }}
    {%- endif %}
{%- endmacro %}
