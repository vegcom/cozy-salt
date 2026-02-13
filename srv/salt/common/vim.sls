# vim configuration deployment
# Deploys vim dotfiles to all managed_users
{% from "_macros/git-repo.sls" import git_repo %}
{% set users = salt['pillar.get']('users', {}) %}
{% set managed_users = salt['pillar.get']('managed_users', []) %}
{% for username in managed_users %}
  {% set userdata = users.get(username, {}) %}
  {% if grains['os'] == 'Windows' %}
    {% set user_home = 'C:\\Users\\' ~ username %}
    {% set user_vim = user_home ~ '\\.vim' %}
  {% else %}
    {% set user_home = userdata.get('home_prefix', '/home') ~ '/' ~ username %}
    {% set user_vim = user_home ~ '/.vim' %}
  {% endif %}
{{ git_repo('cozy-vim', user_vim, username, force_clone=True, force_reset=True, state_id=username + "_vim") }}
{%- endfor %}
