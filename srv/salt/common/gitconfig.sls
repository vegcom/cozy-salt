# Common dotfiles deployment - Git configuration
# Deploys git config ONLY to managed users (never to root)
# Uses Jinja macros to eliminate platform-specific conditionals

{% import 'macros/dotfiles.sls' as dotfiles %}

{% set username = salt['pillar.get']('user:name', 'admin') %}
{% set managed_users = salt['pillar.get']('managed_users', []) %}

# Only deploy if user is in managed_users list and NOT root
{% if username in managed_users and username != 'root' %}

{% set user_home = dotfiles.get_user_home(username) %}

# Deploy .gitconfig
{{ dotfiles.deploy_file('deploy_gitconfig', user_home, '.gitconfig', 'salt://common/dotfiles/.gitconfig', username) }}

# Deploy .git-credentials
{{ dotfiles.deploy_file('deploy_git_credentials', user_home, '.git-credentials', 'salt://common/dotfiles/.git-credentials', username) }}

# Deploy .gitignore
{{ dotfiles.deploy_file('deploy_gitignore', user_home, '.gitignore', 'salt://common/dotfiles/.gitignore', username) }}

# Deploy .gitconfig.local (user customizations - only create if doesn't exist)
deploy_gitconfig_local:
  file.managed:
    - name: {{ dotfiles.dotfile_path(user_home, '.gitconfig.local') }}
    - source: salt://common/dotfiles/.gitconfig.local
    - user: {{ username }}
    - mode: 644
    - makedirs: True
    - create: False
    - require:
      - user: {{ username }}_user

# Deploy .gitignore.local (user customizations - only create if doesn't exist)
deploy_gitignore_local:
  file.managed:
    - name: {{ dotfiles.dotfile_path(user_home, '.gitignore.local') }}
    - source: salt://common/dotfiles/.gitignore.local
    - user: {{ username }}
    - mode: 644
    - makedirs: True
    - create: False
    - require:
      - user: {{ username }}_user

# Deploy .git_template directory
{{ dotfiles.deploy_directory('deploy_git_template', user_home, '.git_template', 'salt://common/dotfiles/.git_template', username) }}

# Deploy .git_template.local directory
{{ dotfiles.deploy_directory('deploy_git_template_local', user_home, '.git_template.local', 'salt://common/dotfiles/.git_template.local', username) }}

{% else %}
# Git config NOT deployed - user '{{ username }}' not in managed_users list or is root
skip_gitconfig_deployment:
  test.nop:
    - name: Skipping git config deployment for user '{{ username }}'
{% endif %}
