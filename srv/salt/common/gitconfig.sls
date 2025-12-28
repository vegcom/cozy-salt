# Common dotfiles deployment
# Deploys same files to both Windows and Linux (different paths)

{% set is_windows = grains['os_family'] == 'Windows' %}
{% set username = salt['pillar.get']('user:name', 'admin') %}
{% if is_windows %}
  {% set user_home = salt['environ.get']('USERPROFILE', 'C:\\Users\\' ~ username) %}
{% else %}
  {% set user_home = '/home/' ~ username if username != 'root' else '/root' %}
{% endif %}

# Git configuration files (always overwrite)
deploy_gitconfig:
  file.managed:
    {% if is_windows %}
    - name: {{ user_home }}\\.gitconfig
    {% else %}
    - name: {{ user_home }}/.gitconfig
    {% endif %}
    - source: salt://common/dotfiles/.gitconfig
    - user: {{ salt['pillar.get']('user:name', 'admin') }}
    - mode: 644
    - makedirs: True

deploy_git_credentials:
  file.managed:
    {% if is_windows %}
    - name: {{ user_home }}\\.git-credentials
    {% else %}
    - name: {{ user_home }}/.git-credentials
    {% endif %}
    - source: salt://common/dotfiles/.git-credentials
    - user: {{ salt['pillar.get']('user:name', 'admin') }}
    - mode: 644
    - makedirs: True

deploy_gitignore:
  file.managed:
    {% if is_windows %}
    - name: {{ user_home }}\\.gitignore
    {% else %}
    - name: {{ user_home }}/.gitignore
    {% endif %}
    - source: salt://common/dotfiles/.gitignore
    - user: {{ salt['pillar.get']('user:name', 'admin') }}
    - mode: 644
    - makedirs: True

# Local override files - only create if they don't exist (user customizations)
deploy_gitconfig_local:
  file.managed:
    {% if is_windows %}
    - name: {{ user_home }}\\.gitconfig.local
    - creates: {{ user_home }}\\.gitconfig.local
    {% else %}
    - name: {{ user_home }}/.gitconfig.local
    - creates: {{ user_home }}/.gitconfig.local
    {% endif %}
    - source: salt://common/dotfiles/.gitconfig.local
    - user: {{ salt['pillar.get']('user:name', 'admin') }}
    - mode: 644
    - makedirs: True

deploy_gitignore_local:
  file.managed:
    {% if is_windows %}
    - name: {{ user_home }}\\.gitignore.local
    - creates: {{ user_home }}\\.gitignore.local
    {% else %}
    - name: {{ user_home }}/.gitignore.local
    - creates: {{ user_home }}/.gitignore.local
    {% endif %}
    - source: salt://common/dotfiles/.gitignore.local
    - user: {{ salt['pillar.get']('user:name', 'admin') }}
    - mode: 644
    - makedirs: True

# Git template directories
deploy_git_template:
  file.recurse:
    {% if is_windows %}
    - name: {{ user_home }}\\.git_template
    {% else %}
    - name: {{ user_home }}/.git_template
    {% endif %}
    - source: salt://common/dotfiles/.git_template
    - user: {{ salt['pillar.get']('user:name', 'admin') }}
    - dir_mode: 755
    - file_mode: 644
    - makedirs: True
    - clean: False

deploy_git_template_local:
  file.recurse:
    {% if is_windows %}
    - name: {{ user_home }}\\.git_template.local
    {% else %}
    - name: {{ user_home }}/.git_template.local
    {% endif %}
    - source: salt://common/dotfiles/.git_template.local
    - user: {{ salt['pillar.get']('user:name', 'admin') }}
    - dir_mode: 755
    - file_mode: 644
    - makedirs: True
    - clean: False
