# Linux Miniforge system-wide installation
# Installs miniforge to /opt/miniforge3 for all users

{%- from "_macros/acl.sls" import cozy_acl %}

{% set miniforge_versions = salt['pillar.get']('versions:miniforge', {}) %}
{% set miniforge_version = miniforge_versions.get('version', '24.11.3-0') %}
{# Path configuration from pillar with defaults #}
{% set miniforge_path = salt['pillar.get']('install_paths:miniforge:linux', '/opt/miniforge3') %}
{# TODO: prep for service_user will be pillar service_user: buildgirl probs #}
{% set managed_users = salt['pillar.get']('managed_users', []) %}
{% set service_user = managed_users[0] if managed_users else 'nobody' %}

# Create nvm directory first (NVM installer requires it to exist)
miniforge_directory:
  file.directory:
    - name: {{ miniforge_path }}
    - mode: "0755"
    - user: {{ service_user }}
    - group: cozyusers
    - makedirs: True
    - clean: False

# Download miniforge installer
miniforge_download:
  cmd.run:
    - name: |
        curl -fsSL -o /tmp/miniforge-init.sh https://github.com/conda-forge/miniforge/releases/download/{{ miniforge_version }}/Miniforge3-Linux-x86_64.sh
    - creates: /tmp/miniforge-init.sh

# Install miniforge system-wide
# -b = batch mode (non-interactive)
# -p = installation prefix
# -s = skip pre/post-link/install scripts (we handle conda init via profile.d)
miniforge_install:
  cmd.run:
    - name: bash /tmp/miniforge-init.sh -b -u -s -p {{ miniforge_path }}
    - require:
      - cmd: miniforge_download
      - file: miniforge_directory
    - creates: {{ miniforge_path }}/bin/conda

# Install base pip packages via common orchestration
include:
  - common.miniforge

# Set ACLs for cozyusers group access
{{ cozy_acl(miniforge_path) }}
