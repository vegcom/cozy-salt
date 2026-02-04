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
