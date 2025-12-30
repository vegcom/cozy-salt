# Common Vim configuration
# Deploys vim config ONLY to managed users (never to root)

{% set is_windows = grains['os_family'] == 'Windows' %}
{% set username = salt['pillar.get']('user:name', 'admin') %}
{% set managed_users = salt['pillar.get']('managed_users', []) %}

# Only deploy if user is in managed_users list and NOT root
{% if username in managed_users and username != 'root' %}

{% if is_windows %}
  {% set user_home = salt['environ.get']('USERPROFILE', 'C:\\Users\\' ~ username) %}
{% else %}
  {% set user_home = '/home/' ~ username %}
{% endif %}

# Deploy .vim directory with all configs
deploy_vim_directory:
  file.recurse:
    {% if is_windows %}
    - name: {{ user_home }}\\.vim
    {% else %}
    - name: {{ user_home }}/.vim
    {% endif %}
    - source: salt://common/dotfiles/.vim
    - user: {{ username }}
    - dir_mode: 755
    - file_mode: 644
    - makedirs: True
    - clean: False

# Create symlink ~/.vimrc -> ~/.vim/vimrc
deploy_vimrc_symlink:
  file.symlink:
    {% if is_windows %}
    - name: {{ user_home }}\\.vimrc
    - target: {{ user_home }}\\.vim\\vimrc
    {% else %}
    - name: {{ user_home }}/.vimrc
    - target: {{ user_home }}/.vim/vimrc
    {% endif %}
    - user: {{ username }}
    - makedirs: True
    - require:
      - file: deploy_vim_directory

{% else %}
# Vim config NOT deployed - user '{{ username }}' not in managed_users list or is root
skip_vim_deployment:
  test.nop:
    - name: Skipping vim deployment for user '{{ username }}'
{% endif %}
