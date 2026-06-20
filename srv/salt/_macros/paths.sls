{%- macro managed_tree(name, source, user='root', group='root',
                       dir_mode='0755', file_mode='0644',
                       clean=False, require=None, order=None, recurse=False) %}

{#- manage path #}
{{ name }}_dir:
  file.directory:
    - name: {{ name }}
    - user: {{ user }}
    - group: {{ group }}
    - mode: "{{ dir_mode }}"
    {%- if require %}
    - require:
      - {{ require }}
    {%- endif %}
    {%- if order is not none %}
    - order: {{ order }}
    {%- endif %}

{# recursively place files #}
{{ name }}_files:
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
      - file: {{ name }}_dir
    {%- if order is not none %}
    - order: {{ order }}
    {%- endif %}
{%- endmacro %}
