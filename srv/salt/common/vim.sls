# vim configuration deployment
# Deploys vim dotfiles to all managed_users (Linux only)

{%- from '_macros/dotfiles.sls' import get_user_home %}
{%- from "_macros/git-repo.sls" import git_repo %}

{%- if grains['os'] != 'Windows' %}
  {%- set usernames = salt['pillar.get']('managed_users', [], merge=True) %}
  {%- for username in usernames %}
    {%- set user_home = get_user_home(username) | trim %}
    {%- if user_home %}
      {%- set user_vim = user_home ~ '/.vim' %}
{{ git_repo('cozy-vim', user_vim, username, force_clone=True, force_reset=True, state_id=username + "_vim") }}
    {%- endif %}
  {%- endfor %}
{%- endif %}
