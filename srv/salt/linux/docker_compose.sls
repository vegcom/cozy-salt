{%- from '_macros/paths.sls' import managed_tree with context %}

{%- set docker_enabled = salt['pillar.get']('host:capabilities:docker', False) %}
{%- set managed_users = salt['pillar.get']('managed_users', [], merge=True) -%}
{%- set run_user = managed_users[0] if managed_users else '' -%}
{%- set cozy_docker = salt['pillar.get']('install_paths:docker:linux') %}
{%- set is_container = salt['file.file_exists']('/.dockerenv') or salt['file.file_exists']('/run/.containerenv') -%}
{%- set pillar_ref_prefix = '__salt_pillar_' %}
{%- if run_user and not is_container %}
  {%- if docker_enabled %}
    {%- set config = salt['pillar.get']('docker_compose', {}) %}
    {%- set _id = salt['grains.get']('id') %}

{{ managed_tree(cozy_docker,
                'salt://linux/files/opt-cozy-docker',
                user='cozy-salt-svc', group='cozyusers',
                recurse=True, clean=True,
                dir_mode='0775', file_mode='0665') }}

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
      {%- set env = entry.get('env', {}) %}
      {%- if files is string %}{%- set files = [files] %}{%- endif %}
        {%- set files_args = files | map('regex_replace', '^(.*)$', '-f \\1') | join(' ') %}
        {%- set compose_cmd = 'docker --context default compose ' ~ files_args ~ ' up -d --build --remove-orphans' %}

docker_compose_up_{{ name.replace("-", "_") }}:
  cmd.run:
    - name: {{ compose_cmd }}
    - runas: {{ run_user }}
    - cwd: {{ path }}
    {%- if env %}
    - env:
      {%- for k, v in env.items() %}
        {%- set is_pillar_ref = (v is string) and v.startswith(pillar_ref_prefix) %}
        {%- if is_pillar_ref %}
      - {{ k }}: {{ salt['pillar.get'](v.replace(pillar_ref_prefix, '', 1), '') | tojson }}
        {%- else %}
      - {{ k }}: {{ v | tojson }}
        {%- endif %}
      {%- endfor %}
    {%- endif %}
    {%- endfor %}
  {%- else %}
docker_not_enabled:
  test.nop:
    - name: Skipping docker_compose
  {%- endif %}
{%- endif %}
