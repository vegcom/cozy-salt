# vim configuration deployment
# Deploys vim dotfiles to all managed_users

{%- import '_macros/dotfiles.sls' as dotfiles %}
{%- from "_macros/git-repo.sls" import git_repo %}

{%- set is_windows = grains['os'] == 'Windows' %}
{%- set users = salt['pillar.get']('users', {}) %}
{%- set managed_users = salt['pillar.get']('managed_users', [], merge=True) %}

{%- if not is_windows %}
  {%- set usernames = managed_users %}
{%- else %}
  {%- from '_macros/windows.sls' import get_users_with_profiles with context %}
  {%- set usernames = get_users_with_profiles().split(',') %}
{%- endif %}

{%- for username in usernames %}
  {%- set userdata = users.get(username, {}) %}
  {%- set user_home = dotfiles.get_user_home(username) %} # FIXME: get_user_home provides all homes for all users
  {%- if username in user_home %}
    {%- set user_vim = user_home ~ '/.vim' %}
{{ git_repo('cozy-vim', user_vim, username, force_clone=True, force_reset=True, state_id=username + "_vim") }}
  {%- endif %}
{%- endfor %}
