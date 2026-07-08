# vim configuration deployment
# Deploys vim dotfiles to all managed_users
{%- import '_macros/dotfiles.sls' as dotfiles %}
{%- from "_macros/git-repo.sls" import git_repo %}
{%- set users = salt['pillar.get']('users', {}) %}
{%- set managed_users = salt['pillar.get']('managed_users', [], merge=True) %}
{%- for username in managed_users %}
  {%- set userdata = users.get(username, {}) %}
  {%- set user_home = dotfiles.get_user_home(username) %}
  {%- set user_vim = user_home ~ '/.vim' %}
{{ git_repo('cozy-vim', user_vim, username, force_clone=True, force_reset=True, state_id=username + "_vim") }}
{%- endfor %}
