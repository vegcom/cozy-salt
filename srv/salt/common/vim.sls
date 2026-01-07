# Common Vim configuration
# Deploys vim config ONLY to managed users (never to root)
# Uses Jinja macros to eliminate platform-specific conditionals

{% import 'common/_dotfiles_macros.sls' as dotfiles %}

{% set username = salt['pillar.get']('user:name', 'admin') %}
{% set managed_users = salt['pillar.get']('managed_users', []) %}

# Only deploy if user is in managed_users list and NOT root
{% if username in managed_users and username != 'root' %}

{% set user_home = dotfiles.get_user_home(username) %}

# Deploy .vim directory with all configs
{{ dotfiles.deploy_directory('deploy_vim_directory', user_home, '.vim', 'salt://common/dotfiles/.vim', username) }}

# Create symlink ~/.vimrc -> ~/.vim/vimrc
{{ dotfiles.deploy_symlink('deploy_vimrc_symlink', user_home, '.vimrc', '.vim/vimrc', username, require='deploy_vim_directory') }}

{% else %}
# Vim config NOT deployed - user '{{ username }}' not in managed_users list or is root
skip_vim_deployment:
  test.nop:
    - name: Skipping vim deployment for user '{{ username }}'
{% endif %}
