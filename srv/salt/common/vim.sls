# Common Vim configuration
# Deploys vim config to both Windows and Linux (different paths)

{% set is_windows = grains['os_family'] == 'Windows' %}
{% set username = salt['pillar.get']('user:name', 'admin') %}
{% if is_windows %}
  {% set user_home = salt['environ.get']('USERPROFILE', 'C:\\Users\\' ~ username) %}
  {% set separator = '\\' %}
{% else %}
  {% set user_home = '/home/' ~ username if username != 'root' else '/root' %}
  {% set separator = '/' %}
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
    - user: {{ salt['pillar.get']('user:name', 'admin') }}
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
    - user: {{ salt['pillar.get']('user:name', 'admin') }}
    - makedirs: True
    - require:
      - file: deploy_vim_directory
