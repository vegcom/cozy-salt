# Git configuration deployment
# Deploys git dotfiles to all managed_users
# See docs/modules/common-gitconfig.md for usage

{% import 'macros/dotfiles.sls' as dotfiles %}

{% set managed_users = salt['pillar.get']('managed_users', []) %}
{% set is_windows = grains['os'] == 'Windows' %}
{# Merge global and user-specific github tokens #}
{% set global_tokens = salt['pillar.get']('github:tokens', []) %}
{% set users_data = salt['pillar.get']('users', {}) %}
# Configure git to trust all directories (works around Git 2.36+ dubious ownership check)
# Run once before deploying to any user (runs as minion user on Windows, first managed user on Linux)
git_safe_directory_all:
  cmd.run:
    - name: git config --global --add safe.directory '*'
    - unless: git config --global --get-regexp '^safe.directory' | grep -q '\*'

# Deploy to each managed user
{% for username in managed_users %}
{% set user_home = dotfiles.get_user_home(username) %}
{# Merge global and user-specific github tokens #}
{% set user_tokens = users_data.get(username, {}).get('github', {}).get('tokens', []) %}
{% set merged_tokens = global_tokens + user_tokens %}

# Deploy base .gitconfig (always update)
deploy_gitconfig_{{ username }}:
  file.managed:
    - name: {{ dotfiles.dotfile_path(user_home, '.gitconfig') }}
    - source: salt://common/dotfiles/.gitconfig
{% if not is_windows %}
    - user: {{ username }}
    - mode: 644
{% endif %}
    - makedirs: True

# Deploy .git-credentials from merged global and user-specific tokens
deploy_git_credentials_{{ username }}:
  file.managed:
    - name: {{ dotfiles.dotfile_path(user_home, '.git-credentials') }}
    - contents: |
        {%- for token in merged_tokens %}
        https://{{ username }}:{{ token }}@github.com
        {%- endfor %}
{% if not is_windows %}
    - user: {{ username }}
    - mode: 600
{% endif %}
    - makedirs: True
    - require:
      - file: deploy_gitconfig_{{ username }}

# Deploy base .gitignore (always update)
deploy_gitignore_{{ username }}:
  file.managed:
    - name: {{ dotfiles.dotfile_path(user_home, '.gitignore') }}
    - source: salt://common/dotfiles/.gitignore
{% if not is_windows %}
    - user: {{ username }}
    - mode: 644
{% endif %}
    - makedirs: True

# Deploy .gitconfig.local (create once only, user customizations)
deploy_gitconfig_local_{{ username }}:
  file.managed:
    - name: {{ dotfiles.dotfile_path(user_home, '.gitconfig.local') }}
    - source: salt://common/dotfiles/.gitconfig.local
{% if not is_windows %}
    - user: {{ username }}
    - mode: 644
{% endif %}
    - makedirs: True
    - create: False

# Deploy .gitignore.local (create once only, user customizations)
deploy_gitignore_local_{{ username }}:
  file.managed:
    - name: {{ dotfiles.dotfile_path(user_home, '.gitignore.local') }}
    - source: salt://common/dotfiles/.gitignore.local
{% if not is_windows %}
    - user: {{ username }}
    - mode: 644
{% endif %}
    - makedirs: True
    - create: False

# Deploy .vim directory via git (clone cozy-vim.git for each user)
deploy_vim_{{ username }}:
  git.latest:
    - name: https://github.com/vegcom/cozy-vim.git
    - target: {{ dotfiles.dotfile_path(user_home, '.vim') }}
{% if not is_windows %}
    - user: {{ username }}
{% endif %}
    - branch: main
    - force_clone: True
    - force_reset: True
    - require:
      - cmd: git_safe_directory_all
      - file: deploy_git_credentials_{{ username }}
{% if is_windows %}
      - file: deploy_git_credentials_system
{% endif %}

# Deploy .git_template directory (always update)
deploy_git_template_{{ username }}:
  file.recurse:
    - name: {{ dotfiles.dotfile_path(user_home, '.git_template') }}
    - source: salt://common/dotfiles/.git_template
{% if not is_windows %}
    - user: {{ username }}
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
{% if not is_windows %}
    - user: {{ username }}
    - dir_mode: 755
    - file_mode: 644
{% endif %}
    - makedirs: True
    - clean: False

{% endfor %}

# On Windows: Deploy global .git-credentials to SYSTEM's home
# (SYSTEM runs the minion and needs credentials to clone private repos)
{% if is_windows %}
deploy_git_credentials_system:
  file.managed:
    - name: C:\Windows\System32\config\systemprofile\.git-credentials
    - contents: |
        {%- for token in global_tokens %}
        https://oauth2:{{ token }}@github.com
        {%- endfor %}
    - makedirs: True
    - require:
      - cmd: git_safe_directory_all
{% endif %}
