# Linux Node.js version management via nvm
# System-wide installation to /opt/nvm with NPM prefix management
# No per-user profile pollution - initialized via /etc/profile.d/nvm.sh
# Global npm packages installed via common.nvm orchestration

{%- from "_macros/acl.sls" import cozy_acl %}

{% set nvm_config = salt['pillar.get']('nvm', {}) %}
{% set default_version = nvm_config.get('default_version', 'lts/*') %}
{% set _pinned = salt['pillar.get']('versions:nvm:version', '') %}
{% set nvm_version = _pinned or salt['github_release.latest']('nvm-sh/nvm') %}
{# Path configuration from pillar with defaults #}
{% set nvm_path = salt['pillar.get']('install_paths:nvm:linux', '/opt/nvm') %}
{%- set service_user = salt['pillar.get']('service_user:name', 'cozy-salt-svc') %}

# Create nvm directory first (NVM installer requires it to exist)
nvm_directory:
  file.directory:
    - name: {{ nvm_path }}
    - mode: "0755"
    - user: {{ service_user }}
    - group: cozyusers
    - makedirs: True
    - clean: False

# Download and install NVM system-wide
# NVM_DIR - custom installation path (no trailing slash!)
# PROFILE=/dev/null - prevents auto-modification of shell profiles
# Note: Runs as root (needed for /opt directory ownership) but in clean environment
nvm_download_and_install:
  cmd.run:
    - name: |
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/{{ nvm_version }}/install.sh | \
          NVM_DIR={{ nvm_path }} PROFILE=/dev/null bash
    - runas: {{ service_user }}
    - creates: {{ nvm_path }}/nvm.sh
    - require:
      - file: nvm_directory

nvm_directory_perms:
  file.directory:
    - name: {{ nvm_path }}
    - user: {{ service_user }}
    - group: cozyusers
    - dir_mode: "0755"
    - file_mode: "0775"
    - makedirs: True
    - recurse:
      - user
      - group
    - include_empty: True
    - require:
      - file: nvm_directory
      - cmd: nvm_download_and_install

# Install default Node.js version system-wide
# Use BASH_ENV for non-interactive shells (Salt cmd.run)
# This ensures NVM is sourced even without -i (interactive) flag
# NOTE: Only NVM_DIR during installation - NVM rejects PREFIX and NPM_CONFIG_PREFIX
nvm_install_default_version:
  cmd.run:
    - name: |
        nvm install {{ default_version }} && nvm alias default {{ default_version }}
    - shell: /bin/bash
    - runas: {{ service_user }}
    - unless: test -d {{ nvm_path }}/versions/node
    - require:
      - cmd: nvm_download_and_install
      - file: nvm_directory_perms
    - env:
      - BASH_ENV: /etc/profile.d/nvm.sh
      - NVM_DIR: {{ nvm_path }}

# Install global npm packages via common orchestration
include:
  - common.nvm

# Set ACLs for cozyusers group access
{{ cozy_acl(nvm_path) }}
