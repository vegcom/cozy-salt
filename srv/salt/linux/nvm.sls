# Linux Node.js version management via nvm
# Installs nvm and configures default Node.js version

{% import_yaml 'packages.sls' as packages %}
{% set nvm_config = salt['pillar.get']('nvm', {}) %}
{% set default_version = nvm_config.get('default_version', 'lts/*') %}
{% set user = salt['pillar.get']('user:name', 'admin') %}
{% set user_home = '/home/' ~ user if user != 'root' else '/root' %}

install_nvm:
  cmd.run:
    - name: |
        curl -sS -o /tmp/nvm-install.sh https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh
        bash /tmp/nvm-install.sh
        rm -f /tmp/nvm-install.sh
        # Source profile to initialize nvm
        if [ -f ~/.bashrc ]; then source ~/.bashrc; fi
    - runas: {{ user }}
    - shell: /bin/bash
    - creates: {{ user_home }}/.nvm/nvm.sh
    - env:
      - HOME: {{ user_home }}

install_default_node_version:
  cmd.run:
    - name: bash -il -c "nvm install {{ default_version }} && nvm alias default {{ default_version }}"
    - runas: {{ user }}
    - require:
      - cmd: install_nvm
    - creates: {{ user_home }}/.nvm/versions/node/v*/bin/node
    - env:
      - HOME: {{ user_home }}

{% for package in packages.npm_global %}
install_npm_{{ package | replace('/', '_') | replace('@', '') | replace('-', '_') }}:
  cmd.run:
    - name: bash -il -c "nvm use default && npm install -g {{ package }}"
    - runas: {{ user }}
    - require:
      - cmd: install_default_node_version
    - unless: bash -il -c "npm list -g --depth=0 | grep -q {{ package }}"
    - env:
      - HOME: {{ user_home }}
{% endfor %}
