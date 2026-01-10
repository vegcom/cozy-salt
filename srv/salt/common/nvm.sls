# Common Node.js version management orchestration
# Installs global npm packages (cross-platform)
# Platform-specific NVM installation delegated to linux.nvm or windows.nvm

{% import_yaml "packages.sls" as packages %}
{% set nvm_config = salt['pillar.get']('nvm', {}) %}

# nvm on windows does not accept wildcards
{% set default_version = nvm_config.get('default_version', 'lts') %}

# Install global npm packages (if defined)
# All packages installed in single command for efficiency
{% set npm_packages = packages.get('npm_global', []) %}

{# Path configuration from pillar with defaults - platform-specific #}
{% if grains['os_family'] == 'Windows' %}
{% set nvm_path = salt['pillar.get']('install_paths:nvm:windows', 'C:\\opt\\nvm') %}
{% set node_path = nvm_path ~ '\\nodejs' %}
{% set npm_bin = node_path ~ '\\npm.cmd' %}
{% else %}
{% set nvm_path = salt['pillar.get']('install_paths:nvm:linux', '/opt/nvm') %}
{% endif %}

{% if npm_packages %}
install_npm_global_packages:
  cmd.run:
    {% if grains['os_family'] == 'Windows' %}
    - name: {{ npm_bin }} install -g {{ npm_packages | join(' ') }}
    - shell: pwsh
    - env:
      - NVM_HOME: {{ nvm_path }}
      - NVM_SYMLINK: {{ node_path }}
    - require:
      - cmd: nvm_use_default
    {% else %}
    - name: NPM_CONFIG_PREFIX={{ nvm_path }} npm install -g {{ npm_packages | join(' ') }}
    - shell: /bin/bash
    - env:
      - BASH_ENV: /etc/profile.d/nvm.sh
      - NVM_DIR: {{ nvm_path }}
    - require:
      - cmd: nvm_install_default_version
    {% endif %}
{% endif %}
