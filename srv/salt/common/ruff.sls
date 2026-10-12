{%- import '_macros/dotfiles.sls' as dotfiles %}

{%- set is_windows = grains['os'] == 'Windows' %}
{%- set managed_users = salt['pillar.get']('managed_users', [], merge=True) %}

{%- for username in managed_users %}
  {%- set users_data = salt['pillar.get']('users', {}) %}
  {%- set user_home = dotfiles.get_user_home(username) %}
  {%- set file_path = dotfiles.dotfile_path(user_home, '.ruff.toml') %}

  {%- set file_exists = salt['file.file_exists'](file_path) %}
  {%- if not file_exists %}
    {%- do salt['log.info'](file_path ~ ': does not exist') %}
deploy_ruff_{{ username }}:
  file.managed:
    - name: {{ file_path }}
    - source: salt://common/dotfiles/.ruff.toml
        {%- if not is_windows %}
    - user: {{ username }}
    - mode: "0644"
        {%- else %}
    - win_perms_reset: True
        {%- endif %}
    - makedirs: True
  {%- else %}
{%- do salt['log.warning'](file_path ~ ': exists') %}
  {%- endif %}
{%- endfor %}
