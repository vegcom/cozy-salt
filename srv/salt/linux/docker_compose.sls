{%- set docker_enabled = salt['pillar.get']('host:capabilities:docker', False) %}
{%- set managed_users = salt['pillar.get']('managed_users', [], merge=True) -%}
{%- set run_user = managed_users[0] if managed_users else '' -%}
{%- set is_container = salt['file.file_exists']('/.dockerenv') or salt['file.file_exists']('/run/.containerenv') -%}
{%- if run_user and not is_container %}
  {%- if docker_enabled %}
    {%- set config = salt['pillar.get']('docker_compose', {}) %}
    {%- set _id = salt['grains.get']('id') %}
docker_member_{{ run_user }}:
  group.present:
    - name: docker
    - addusers:
      - {{ run_user }}
    - unless: getent group docker|grep -q {{ run_user }}
    {%- for name, entry in config.items() %}
      {%- set services = entry.get('services', {}) %}
      {%- set path = entry.get('path', '') %}
      {%- set files = entry.get('files', []) %}
      {%- if files is string %}{%- set files = [files] %}{%- endif %}
        {%- set files_args = files | map('regex_replace', '^(.*)$', '-f \\1') | join(' ') %}
        {%- set compose_cmd = 'docker --context default compose --quiet-build --quiet-pull ' ~ files_args ~ ' up -d --build --remove-orphans' %}
docker_compose_up_{{ name.replace("-", "_") }}:
  cmd.run:
    - name: {{ compose_cmd }}
    - runas: {{ run_user }}
    - cwd: {{ path }}
    - unless: docker --context default compose {{ files_args }} ps -q | grep -q .
    {%- endfor %}
  {%- else %}
docker_not_enabled:
  test.nop:
    - name: Skipping docker_compose
  {%- endif %}
{%- endif %}
