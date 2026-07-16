#!jinja|yaml
{%- macro get_packages() -%}
  {%- if salt['cp.get_file_str']('salt://packages.sls') %}
    {{ salt['slsutil.renderer']('salt://packages.sls', default_renderer='jinja|yaml') | tojson }}
  {%- else %}
    {{ {} | tojson }}
  {%- endif %}
{%- endmacro %}
