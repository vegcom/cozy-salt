{#-
  Load secrets based on capabilities; hosts pillar to eval capabilities, id from grains
  gates pillar load based on capibility
  capabilities_list - example at srv/pillar/host/example.sls
#}
{%- set _id = salt["grains.get"]("id") %}
{%- set _id = grains.id %}
{%- set pillar_root = "/srv/pillar" %}
{%- set host_sls = pillar_root ~ '/host/' ~ _id ~ ".sls" %}
{%- set host_path = 'host.' ~ _id %}
{#- compute secrets from enabled caps #}
{%- set base_path = "secrets" %}
{%- set capabilities_dict = salt['pillar.get']("host:capabilities", {}) %}
{%- set capabilities_list = [] %}
{%- for cap, enabled in capabilities_dict.items() %}
  {%- if enabled %}
    {%- do capabilities_list.append(cap) %}
  {%- endif %}
{%- endfor %}
{#- add base includes  #}
{%- set includes_list = ["git", "mgmt", "salt", "services", "network", "headscale"] %}  # FIXME: 'headscale' added to overcome render bug
{%- if includes_list %}
include:
  {%- for include in includes_list + capabilities_list %}
    {%- if include %}
      {%- set include_path = pillar_root ~ "/secrets/" ~ include ~ ".sls" %}
      {%- set include_name = base_path ~ "." ~ include %}
      {%- set test = salt['slsutil.renderer'](include_path, default_renderer='yaml', ignore_missing=True) %}
      {%- if test is not none %}
        {#- include -  only after checking if file exists #}
  - {{ include_name }}
        {#- include - yeesh~ #}
      {%- endif %}
    {%- endif %}
  {%- endfor %}
{%- endif %}
