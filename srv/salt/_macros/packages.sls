{%- macro get_packages() -%}
{%- if salt['cp.get_file_str']('salt://packages.sls') %}
  {%- set packages = salt['slsutil.renderer']('salt://packages.sls', default_renderer=jinja) %}
{%- else %}
  {%- set packages = {} %}
{%- endif %}
{%- endmacro %}
