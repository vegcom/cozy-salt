# Windows Node.js version management via nvm-windows
# Assumes nvm-windows is already installed via chocolatey

{% import_yaml 'packages.sls' as packages %}
{% set nvm_config = salt['pillar.get']('nvm', {}) %}
{% set default_version = nvm_config.get('default_version', 'lts') %}

install_default_node_version:
  cmd.run:
    - name: nvm install {{ default_version }} && nvm use {{ default_version }} && nvm alias default {{ default_version }}
    - shell: powershell
    - unless: nvm list | findstr "{{ default_version }}"

{% for package in packages.npm_global %}
install_npm_{{ package | replace('/', '_') | replace('@', '') | replace('-', '_') }}:
  cmd.run:
    - name: npm install -g {{ package }}
    - shell: powershell
    - require:
      - cmd: install_default_node_version
    - unless: npm list -g --depth=0 | findstr "{{ package }}"
{% endfor %}
