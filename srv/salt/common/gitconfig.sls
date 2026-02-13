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
# On Windows: use --system so it applies to all users including SYSTEM (which runs git.latest)
# On Linux: use --global for the root user running Salt
git_safe_directory_all:
  cmd.run:
{% if is_windows %}
    - name: git config --system --add safe.directory '*'
    - unless: git config --system --get-regexp '^safe.directory' | Select-String -Quiet '\*'
    - shell: powershell
{% else %}
    - name: git config --global --add safe.directory '*'
    - unless: git config --global --get-regexp '^safe.directory' | grep -q '\*'
{% endif %}

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
    - mode: "0644"
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
    - mode: "0600"
{% endif %}
    - makedirs: True
    - require:
      - file: deploy_gitconfig_{{ username }}

# Deploy base gitattributes (always update)
deploy_gitattributes_{{ username }}:
  file.managed:
    - name: {{ dotfiles.dotfile_path(user_home, '.gitattributes') }}
    - source: salt://common/dotfiles/.gitattributes
{% if not is_windows %}
    - user: {{ username }}
    - mode: "0644"
{% endif %}
    - makedirs: True

# Deploy base .gitmessage (always update)
deploy_gitmessage_{{ username }}:
  file.managed:
    - name: {{ dotfiles.dotfile_path(user_home, '.gitmessage') }}
    - source: salt://common/dotfiles/.gitmessage
{% if not is_windows %}
    - user: {{ username }}
    - mode: "0644"
{% endif %}
    - makedirs: True

# Deploy base .gitignore (always update)
deploy_gitignore_{{ username }}:
  file.managed:
    - name: {{ dotfiles.dotfile_path(user_home, '.gitignore') }}
    - source: salt://common/dotfiles/.gitignore
{% if not is_windows %}
    - user: {{ username }}
    - mode: "0644"
{% endif %}
    - makedirs: True

# Deploy .gitconfig.local with user github config if present in pillar
{% set github_config = users_data.get(username, {}).get('github', {}) %}
{% set git_email = github_config.get('email', '') %}
{% set git_name = github_config.get('name', '') %}
deploy_gitconfig_local_{{ username }}:
  file.managed:
    - name: {{ dotfiles.dotfile_path(user_home, '.gitconfig.local') }}
{% if git_email and git_name %}
    - contents: |
        [user]
            email = {{ git_email }}
            name = {{ git_name }}
    - replace: True
{% else %}
    - source: salt://common/dotfiles/.gitconfig.local
    - replace: False
    - create: True
{% endif %}
{% if not is_windows %}
    - user: {{ username }}
    - mode: "0644"
{% endif %}
    - makedirs: True

# Deploy .gitattributes.local (create once only, user customizations)
deploy_gitattributes_local_{{ username }}:
  file.managed:
    - name: {{ dotfiles.dotfile_path(user_home, '.gitattributes.local') }}
    - source: salt://common/dotfiles/.gitattributes.local
{% if not is_windows %}
    - user: {{ username }}
    - mode: "0644"
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
    - mode: "0644"
{% endif %}
    - makedirs: True
    - create: False

# Deploy .profile for PATH setup (Linux only)
{% if not is_windows %}
deploy_profile_{{ username }}:
  file.managed:
    - name: {{ dotfiles.dotfile_path(user_home, '.profile') }}
    - source: salt://linux/files/etc-skel/.profile
    - user: {{ username }}
    - mode: "0644"
    - makedirs: True
{% endif %}

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
    - dir_mode: "0755"
    - file_mode: "0644"
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
    - dir_mode: "0755"
    - file_mode: "0644"
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
