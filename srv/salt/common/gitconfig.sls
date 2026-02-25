# Git configuration deployment
# Deploys git dotfiles to all managed_users
# See docs/modules/common-gitconfig.md for usage

{% import '_macros/dotfiles.sls' as dotfiles %}

{% set managed_users = salt['pillar.get']('managed_users', [], merge=True) %}
{% set is_windows = grains['os'] == 'Windows' %}
{# Merge global and user-specific github tokens #}
{% set global_tokens = salt['pillar.get']('github:tokens', []) %}
{% set users_data = salt['pillar.get']('users', {}) %}

# Deploy to each managed user
{% for username in managed_users %}
{% set user_home = dotfiles.get_user_home(username) %}
{# Merge global and user-specific github tokens #}
{% set user_tokens = users_data.get(username, {}).get('github', {}).get('tokens', []) %}
{% set merged_tokens = global_tokens + user_tokens %}

# Deploy .git-credentials from merged global and user-specific tokens
deploy_git_credentials_{{ username }}:
  file.managed:
    - name: {{ dotfiles.dotfile_path(user_home, '.git-credentials') }}
    - contents: |
        {%- for token in merged_tokens %}
        https://{{ username }}:{{ token }}@github.com
        {%- endfor %}
    - user: {{ username }}
{% if not is_windows %}
    - mode: "0600"
{% else %}
    - win_perms_reset: True
{% endif %}
    - makedirs: True
    - require:
      - file: deploy_gitconfig_{{ username }}

# Deploy base gitattributes (always update)
deploy_gitattributes_{{ username }}:
  file.managed:
    - name: {{ dotfiles.dotfile_path(user_home, '.gitattributes') }}
    - source: salt://common/dotfiles/.gitattributes
    - user: {{ username }}
{% if not is_windows %}
    - mode: "0644"
{% else %}
    - win_perms_reset: True
{% endif %}
    - makedirs: True

# Deploy base .gitmessage (always update)
deploy_gitmessage_{{ username }}:
  file.managed:
    - name: {{ dotfiles.dotfile_path(user_home, '.gitmessage') }}
    - source: salt://common/dotfiles/.gitmessage
    - user: {{ username }}
{% if not is_windows %}
    - mode: "0644"
{% else %}
    - win_perms_reset: True
{% endif %}
    - makedirs: True

# Deploy base .gitignore (always update)
deploy_gitignore_{{ username }}:
  file.managed:
    - name: {{ dotfiles.dotfile_path(user_home, '.gitignore') }}
    - source: salt://common/dotfiles/.gitignore
    - replace: True
    - user: {{ username }}
{% if not is_windows %}
    - mode: "0644"
{% else %}
    - win_perms_reset: True
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
    - user: {{ username }}
{% if not is_windows %}
    - mode: "0644"
{% endif %}
    - makedirs: True

# Deploy .git_template directory (always update)
deploy_git_template_{{ username }}:
  file.recurse:
    - name: {{ dotfiles.dotfile_path(user_home, '.git_template') }}
    - source: salt://common/dotfiles/.git_template
    - user: {{ username }}
{% if not is_windows %}
    - dir_mode: "0755"
    - file_mode: "0644"
{% else %}
    - win_perms_reset: True
{% endif %}
    - makedirs: True
    - clean: True

{% if not is_windows %}
# Fix hook executability (file.recurse sets 0644 for everything)
git_template_hooks_executable_{{ username }}:
  file.directory:
    - name: {{ dotfiles.dotfile_path(user_home, '.git_template/hooks') }}
    - file_mode: "0755"
    - recurse:
      - mode
    - require:
      - file: deploy_git_template_{{ username }}
{% endif %}

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
