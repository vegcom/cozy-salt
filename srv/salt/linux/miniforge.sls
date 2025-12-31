# Linux Miniforge system-wide installation
# Installs miniforge to /opt/miniforge3 for all users

{% set miniforge_versions = salt['pillar.get']('versions:miniforge', {}) %}
{% set miniforge_version = miniforge_versions.get('version', '24.11.3-0') %}

# Download miniforge installer
miniforge_download:
  cmd.run:
    - name: |
        curl -fsSL -o /tmp/miniforge-init.sh https://github.com/conda-forge/miniforge/releases/download/{{ miniforge_version }}/Miniforge3-Linux-x86_64.sh
    - creates: /tmp/miniforge-init.sh

# Install miniforge system-wide to /opt/miniforge3
# -b = batch mode (non-interactive)
# -p = installation prefix
# -s = skip pre/post-link/install scripts (we handle conda init via profile.d)
miniforge_install:
  cmd.run:
    - name: |
        bash /tmp/miniforge-init.sh -b -s -p /opt/miniforge3
        rm -f /tmp/miniforge-init.sh
        chmod -R 755 /opt/miniforge3
    - require:
      - cmd: miniforge_download
    - creates: /opt/miniforge3/bin/conda

# Install base pip packages via common orchestration
include:
  - common.miniforge
