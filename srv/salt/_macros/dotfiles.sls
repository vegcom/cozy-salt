# Dotfile deployment macros for consistent user file management
# Usage: from "_macros/dotfiles.sls" import user_dotfile, user_dotfiles

{%- macro user_dotfile(username, home, filename, source, mode='0644') %}
{{ username }}_{{ filename | replace('/', '_') | replace('.', '_') | replace('-', '_') }}:
  file.managed:
    - name: {{ home }}/{{ filename }}
    - source: {{ source }}
    - user: {{ username }}
    - group: {{ username }}
    - mode: "{{ mode }}"
    - makedirs: True
    - require:
      - file: {{ username }}_home_directory
{%- endmacro %}

{# Deploy multiple dotfiles from a list #}
{%- macro user_dotfiles(username, home, files) %}
{% for f in files %}
{{ user_dotfile(username, home, f.name, f.source, f.get('mode', '0644')) }}
{% endfor %}
{%- endmacro %}

{#- Get platform-appropriate user home directory path -#}
{%- macro get_user_home(username) -%}
  {%- if grains['os_family'] == 'Windows' -%}
    C:\Users\{{ username }}
  {%- else -%}
    /home/{{ username }}
  {%- endif -%}
{%- endmacro -%}

{#- Get platform-appropriate path to a dotfile/directory -#}
{%- macro dotfile_path(user_home, dotfile_name) -%}
  {%- if grains['os_family'] == 'Windows' -%}
    {{ user_home }}\{{ dotfile_name }}
  {%- else -%}
    {{ user_home }}/{{ dotfile_name }}
  {%- endif -%}
{%- endmacro -%}

{#- Deploy a file to user home (handles platform path separators) -#}
{%- macro deploy_file(state_name, user_home, dotfile_name, source, username, creates=None, require_user=True) -%}
{{ state_name }}:
  file.managed:
    - name: {{ dotfile_path(user_home, dotfile_name) }}
    - source: {{ source }}
    - user: {{ username }}
    - mode: "0644"
    - makedirs: True
  {%- if creates %}
    - creates: {{ dotfile_path(user_home, creates) }}
  {%- endif %}
  {%- if require_user %}
    - require:
      - user: {{ username }}_user
  {%- endif %}
{%- endmacro -%}

{#- Deploy a directory recursively (handles platform path separators) -#}
{%- macro deploy_directory(state_name, user_home, dotdir_name, source, username, require_user=True) -%}
{{ state_name }}:
  file.recurse:
    - name: {{ dotfile_path(user_home, dotdir_name) }}
    - source: {{ source }}
    - user: {{ username }}
    - dir_mode: "0755"
    - file_mode: "0644"
    - makedirs: True
    - clean: False
  {%- if require_user %}
    - require:
      - user: {{ username }}_user
  {%- endif %}
{%- endmacro -%}

{#- Create a symlink (handles platform path separators) -#}
{%- macro deploy_symlink(state_name, user_home, link_name, target_name, username, require=None, require_user=True) -%}
{{ state_name }}:
  file.symlink:
    - name: {{ dotfile_path(user_home, link_name) }}
    - target: {{ dotfile_path(user_home, target_name) }}
    - user: {{ username }}
    - makedirs: True
  {%- if require or require_user %}
    - require:
    {%- if require %}
      - file: {{ require }}
    {%- endif %}
    {%- if require_user %}
      - user: {{ username }}_user
    {%- endif %}
  {%- endif %}
{%- endmacro -%}
