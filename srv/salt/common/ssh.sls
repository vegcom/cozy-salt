# ssh configuration deployment
# Deploys ssh dotfiles + authorized_keys to all managed_users

include:
  - common.ssh-keys
{%- from "_macros/git-repo.sls" import git_repo %}
{%- set users = salt['pillar.get']('users', {}) %}
{%- set is_windows = grains['os'] == 'Windows' %}

{%- import '_macros/dotfiles.sls' as dotfiles %}
{%- if not is_windows %}
  {%- set usernames = salt['pillar.get']('managed_users', [], merge=True) %}
{%- else %}
  {%- from '_macros/windows.sls' import get_users_with_profiles with context %}
  {%- set usernames = get_users_with_profiles().split(',') %}
{%- endif %}

{%- for username in usernames %}
  {%- set userdata = users.get(username, {}) %}
  {%- set user_home = dotfiles.get_user_home(username) %}
  {%- set user_ssh = user_home ~ '/.ssh' %}
  {%- if username in user_home %}
{{ git_repo('cozy-ssh', user_ssh, username, force_clone=True, force_reset=True, state_id=username + "_ssh") }}
  {%- endif %}
{%- endfor %}
