#!jinja|yaml
{#- Load all class pillar files. Each self-selects via grain gating.
    Salt merges them via pillar_source_merging_strategy: recurse.
    Add new class names here when adding class files. #}
{%- set known_classes = ['non_root_datadirs', 'nvidia'] %}
include:
{%- for cname in known_classes %}
  {%- set test = salt['slsutil.renderer']('/srv/pillar/class/' ~ cname ~ '.sls', default_renderer='jinja|yaml', ignore_missing=True) %}
  {%- if test is not none %}
  - class.{{ cname }}
  {%- endif %}
{%- endfor %}
