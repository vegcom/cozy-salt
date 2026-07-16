# ssh configuration deployment
# Deploys ssh dotfiles + authorized_keys to all managed_users

include:
  - common.ssh-keys
{%- from "_macros/git-repo.sls" import git_repo %}
{%- set users = salt['pillar.get']('users', {}) %}
{%- set is_windows = grains['os'] == 'Windows' %}
{%- set user_homes = grains.get('user_homes', {}) %}

{%- if not is_windows %}
  {%- set usernames = salt['pillar.get']('managed_users', [], merge=True) %}
{%- else %}
  {%- from '_macros/windows.sls' import get_users_with_profiles with context %}
  {%- set usernames = get_users_with_profiles().split(',') | reject('equalto', '') | list %}
{%- endif %}

{%- for username in usernames %}
  {%- set base_username = username.split('.')[0] %}
  {%- set user_home = user_homes.get(username, user_homes.get(base_username, '')) %}
  {%- set user_ssh = user_home ~ '/.ssh' %}
  {%- if user_home %}
{{ git_repo('cozy-ssh', user_ssh, username, force_clone=True, force_reset=True, state_id=username + "_ssh") }}
  {%- endif %}
{%- endfor %}
