# Linux Miniforge system-wide installation
# Installs miniforge to /opt/miniforge3 for all users

{% set miniforge_versions = salt['pillar.get']('versions:miniforge', {}) %}
{% set miniforge_version = miniforge_versions.get('version', '24.11.3-0') %}
{# Path configuration from pillar with defaults #}
{% set miniforge_path = salt['pillar.get']('install_paths:miniforge:linux', '/opt/miniforge3') %}

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
    - name: |
        bash /tmp/miniforge-init.sh -b -s -p {{ miniforge_path }}
        rm -f /tmp/miniforge-init.sh
        chmod -R 755 {{ miniforge_path }}
    - require:
      - cmd: miniforge_download
    - creates: {{ miniforge_path }}/bin/conda

# Install base pip packages via common orchestration
include:
  - common.miniforge
