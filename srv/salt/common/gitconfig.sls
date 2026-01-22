# Git configuration deployment
# Deploys git dotfiles to all managed_users
# See docs/modules/common-gitconfig.md for usage

{% import 'macros/dotfiles.sls' as dotfiles %}

{% set managed_users = salt['pillar.get']('managed_users', []) %}
{% set is_windows = grains['os'] == 'Windows' %}
{% set github_token = salt['pillar.get']('github:access_token', '') %}

# Deploy to each managed user
{% for username in managed_users %}
{% set user_home = dotfiles.get_user_home(username) %}

# Deploy base .gitconfig (always update)
deploy_gitconfig_{{ username }}:
  file.managed:
    - name: {{ dotfiles.dotfile_path(user_home, '.gitconfig') }}
    - source: salt://common/dotfiles/.gitconfig
    - user: {{ username }}
{% if not is_windows %}
    - mode: 644
{% endif %}
    - makedirs: True

# Deploy .git-credentials (always update)
deploy_git_credentials_{{ username }}:
  file.managed:
    - name: {{ dotfiles.dotfile_path(user_home, '.git-credentials') }}
    - source: salt://common/dotfiles/.git-credentials
    - user: {{ username }}
{% if not is_windows %}
    - mode: 600
{% endif %}
    - makedirs: True

# Deploy base .gitignore (always update)
deploy_gitignore_{{ username }}:
  file.managed:
    - name: {{ dotfiles.dotfile_path(user_home, '.gitignore') }}
    - source: salt://common/dotfiles/.gitignore
    - user: {{ username }}
{% if not is_windows %}
    - mode: 644
{% endif %}
    - makedirs: True

# Deploy .gitconfig.local (create once only, user customizations)
deploy_gitconfig_local_{{ username }}:
  file.managed:
    - name: {{ dotfiles.dotfile_path(user_home, '.gitconfig.local') }}
    - source: salt://common/dotfiles/.gitconfig.local
    - user: {{ username }}
{% if not is_windows %}
    - mode: 644
{% endif %}
    - makedirs: True
    - create: False

# Deploy .gitignore.local (create once only, user customizations)
deploy_gitignore_local_{{ username }}:
  file.managed:
    - name: {{ dotfiles.dotfile_path(user_home, '.gitignore.local') }}
    - source: salt://common/dotfiles/.gitignore.local
    - user: {{ username }}
{% if not is_windows %}
    - mode: 644
{% endif %}
    - makedirs: True
    - create: False

# Configure git to trust .vim directory (works around Git 2.36+ dubious ownership check)
# Needed when repo is owned by different user than who runs git commands
git_safe_directory_vim_{{ username }}:
  cmd.run:
    - name: git config --global --add safe.directory {{ dotfiles.dotfile_path(user_home, '.vim') }}
    - user: {{ username }}
    - onlyif: test -d {{ dotfiles.dotfile_path(user_home, '.vim') }}

# Deploy .vim directory via git (clone cozy-vim.git for each user)
deploy_vim_{{ username }}:
  git.latest:
    - name: https://github.com/vegcom/cozy-vim.git
    - target: {{ dotfiles.dotfile_path(user_home, '.vim') }}
    - user: {{ username }}
    - branch: main
{% if github_token %}
    - https_user: {{ github_token }}
    - https_pass: ''
{% endif %}
    - force_clone: True
    - require:
      - cmd: git_safe_directory_vim_{{ username }}

# Deploy .git_template directory (always update)
deploy_git_template_{{ username }}:
  file.recurse:
    - name: {{ dotfiles.dotfile_path(user_home, '.git_template') }}
    - source: salt://common/dotfiles/.git_template
    - user: {{ username }}
{% if not is_windows %}
    - dir_mode: 755
    - file_mode: 644
{% endif %}
    - makedirs: True
    - clean: True

# Deploy .git_template.local directory (preserve user additions)
deploy_git_template_local_{{ username }}:
  file.recurse:
    - name: {{ dotfiles.dotfile_path(user_home, '.git_template.local') }}
    - source: salt://common/dotfiles/.git_template.local
    - user: {{ username }}
{% if not is_windows %}
    - dir_mode: 755
    - file_mode: 644
{% endif %}
    - makedirs: True
    - clean: False

{% endfor %}
