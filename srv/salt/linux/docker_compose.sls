{%- set docker_enabled = salt['pillar.get']('host:capabilities:docker', False) %}
# docker_enabled: {{ docker_enabled }}
{%- if docker_enabled %}
  {%- set config = salt['pillar.get']('docker_compose', {}) %}
  {%- set _id = salt['grains.get']('id') %}
# config: {{ config }}
  {%- for name, entry in config.items() %}
    {%- set services = entry.get('services', {}) %}
    {%- set path = entry.get('path', '') %}
    {%- set files = entry.get('files', []) %}
    {%- if files is string %}{%- set files = [files] %}{%- endif %}
    {%- set files_args = files | map('regex_replace', '^(.*)$', '-f \\1') | join(' ') %}
    {%- set compose_cmd = 'docker compose ' ~ files_args ~ ' up -d --remove-orphans' %}

# TODO: replace debug with actual states, e.g.:
# {{ name }}_compose_up:
#   cmd.run:
#     - name: {{ compose_cmd }}
#     - cwd: {{ path }}
#     - onchanges:
#       - file: {{ name }}_compose_file  {#- if managing the file via salt #}
#     - unless: docker compose {{ files_args }} ps -q | grep -q .

  {%- endfor %}
{%- else %}
docker_not_enabled:
  test.nop:
    - name: Skipping docker_compose
{%- endif %}
