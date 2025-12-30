# Linux Node.js version management via nvm
# System-wide installation to /opt/nvm with NPM prefix management
# No per-user profile pollution - initialized via /etc/profile.d/nvm.sh

{% set nvm_config = salt['pillar.get']('nvm', {}) %}
{% set nvm_versions = salt['pillar.get']('versions:nvm', {}) %}
{% set default_version = nvm_config.get('default_version', 'lts/*') %}
{% set nvm_version = nvm_versions.get('version', 'v0.40.1') %}

# Create /opt/nvm directory first (NVM installer requires it to exist)
nvm_directory:
  file.directory:
    - name: /opt/nvm
    - mode: 755
    - makedirs: True

# Download and install NVM to /opt/nvm system-wide
# NVM_DIR=/opt/nvm - custom installation path (no trailing slash!)
# PROFILE=/dev/null - prevents auto-modification of shell profiles
# Note: Runs as root (needed for /opt directory ownership) but in clean environment
nvm_download_and_install:
  cmd.run:
    - name: |
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/{{ nvm_version }}/install.sh | \
          NVM_DIR=/opt/nvm PROFILE=/dev/null bash
    - creates: /opt/nvm/nvm.sh
    - require:
      - file: nvm_directory

# Deploy NVM profile.d initialization script first
nvm_profile:
  file.managed:
    - name: /etc/profile.d/nvm.sh
    - source: salt://linux/files/etc-profile.d/nvm.sh
    - mode: 644

# Install default Node.js version system-wide
# Use BASH_ENV for non-interactive shells (Salt cmd.run)
# This ensures NVM is sourced even without -i (interactive) flag
# NOTE: Only NVM_DIR during installation - NVM rejects PREFIX and NPM_CONFIG_PREFIX
nvm_install_default_version:
  cmd.run:
    - name: |
        nvm install {{ default_version }} && nvm alias default {{ default_version }}
    - shell: /bin/bash
    - creates: /opt/nvm/versions/node/v*/bin/node
    - require:
      - cmd: nvm_download_and_install
      - file: nvm_profile
    - env:
      - BASH_ENV: /etc/profile.d/nvm.sh
      - NVM_DIR: /opt/nvm

# Install global npm packages (if defined)
# Set NPM_CONFIG_PREFIX inline in command, not in env (NVM rejects it in shell environment)
{% for package in packages.get('npm_global', []) %}
install_npm_{{ package | replace('/', '_') | replace('@', '') | replace('-', '_') }}:
  cmd.run:
    - name: NPM_CONFIG_PREFIX=/opt/nvm npm install -g {{ package }}
    - shell: /bin/bash
    - require:
      - cmd: nvm_install_default_version
    - unless: npm list -g --depth=0 | grep -q {{ package }}
    - env:
      - BASH_ENV: /etc/profile.d/nvm.sh
      - NVM_DIR: /opt/nvm
{% endfor %}
