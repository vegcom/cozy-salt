# Common Node.js version management orchestration
# Installs global npm packages (cross-platform)
# Platform-specific NVM installation delegated to linux.nvm or windows.nvm

{% import_yaml "provisioning/packages.sls" as packages %}
{% set nvm_config = salt['pillar.get']('nvm', {}) %}

# Install global npm packages (if defined)
# Platform-specific shell and environment handling in linux/nvm and windows/nvm
{% for package in packages.get('npm_global', []) %}
install_npm_{{ package | replace('/', '_') | replace('@', '') | replace('-', '_') }}:
  cmd.run:
    {% if grains['os_family'] == 'Windows' %}
    - name: npm install -g {{ package }}
    - shell: powershell
    - unless: npm list -g --depth=0 | findstr "{{ package }}"
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
