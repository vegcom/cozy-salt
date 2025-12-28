# Linux Node.js version management via nvm
# Installs nvm and configures default Node.js version

{% import_yaml 'packages.sls' as packages %}
{% set nvm_config = salt['pillar.get']('nvm', {}) %}
{% set default_version = nvm_config.get('default_version', 'lts') %}
{% set user = salt['pillar.get']('user:name', 'admin') %}
{% set user_home = '/home/' ~ user if user != 'root' else '/root' %}

install_nvm:
  cmd.run:
    - name: curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    - runas: {{ user }}
    - creates: {{ user_home }}/.nvm/nvm.sh
    - env:
      - HOME: {{ user_home }}

install_default_node_version:
  cmd.run:
    - name: bash -c "source ~/.nvm/nvm.sh && nvm install {{ default_version }} && nvm alias default {{ default_version }}"
    - runas: {{ user }}
    - require:
      - cmd: install_nvm
    - unless: bash -c "source ~/.nvm/nvm.sh && nvm list | grep {{ default_version }}"
    - env:
      - HOME: {{ user_home }}

{% for package in packages.npm_global %}
install_npm_{{ package | replace('/', '_') | replace('@', '') | replace('-', '_') }}:
  cmd.run:
    - name: bash -c "source ~/.nvm/nvm.sh && nvm use default && npm install -g {{ package }}"
    - runas: {{ user }}
    - require:
      - cmd: install_default_node_version
    - unless: bash -c "source ~/.nvm/nvm.sh && npm list -g --depth=0 | grep {{ package }}"
    - env:
      - HOME: {{ user_home }}
{% endfor %}
