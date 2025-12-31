# Common Node.js version management orchestration
# Installs global npm packages (cross-platform)
# Platform-specific NVM installation delegated to linux.nvm or windows.nvm

{% import_yaml "provisioning/packages.sls" as packages %}
{% set nvm_config = salt['pillar.get']('nvm', {}) %}

# nvm on windows does not accept wildcards
{% set default_version = nvm_config.get('default_version', 'lts') %}

# Install global npm packages (if defined)
# Platform-specific shell and environment handling in linux/nvm and windows/nvm
{% for package in packages.get('npm_global', []) %}
install_npm_{{ package | replace('/', '_') | replace('@', '') | replace('-', '_') }}:
  cmd.run:
    {% if grains['os_family'] == 'Windows' %}
    # XXX: nvm alias: does not work on NVM for Windows
    - name: nvm use {{ default_version }} && npm install -g {{ package }}
    - shell: pwsh
    - unless: npm list -g --depth=0 | findstr "{{ package }}"
    # TODO: pillar "C:\opt\nvm"
    - env:
      - NVM_HOME: C:\opt\nvm
    {% else %}
    - name: NPM_CONFIG_PREFIX=/opt/nvm npm install -g {{ package }}
    - shell: /bin/bash
    - unless: npm list -g --depth=0 | grep -q {{ package }}
    - env:
      - BASH_ENV: /etc/profile.d/nvm.sh
      - NVM_DIR: /opt/nvm
    {% endif %}
    - require:
      {% if grains['os_family'] == 'Windows' %}
      - cmd: install_default_node_version
      {% else %}
      - cmd: nvm_install_default_version
      {% endif %}
{% endfor %}
