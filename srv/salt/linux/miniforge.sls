#!jinja|yaml
# Linux Miniforge system-wide installation
# Installs miniforge to /opt/miniforge3 for all users

{%- set _pinned = salt['pillar.get']('versions:miniforge:version', '') %}
{%- set miniforge_version = _pinned or salt['github_release.latest']('conda-forge/miniforge') %}
{%- set cpu_arch = salt['grains.get']('cpuarch', 'x86_64') %}
{# Path configuration from pillar with defaults #}
{%- set miniforge_path = salt['pillar.get']('install_paths:miniforge:linux', '/opt/miniforge3') %}
{%- set service_user = salt['pillar.get']('service_user:name', 'cozy-salt-svc') %}

# Create nvm directory first (NVM installer requires it to exist)
miniforge_directory:
  file.directory:
    - name: {{ miniforge_path }}
    - mode: "0755"
    - user: {{ service_user }}
    - group: cozyusers
    - makedirs: True
    - clean: False
    - recurse:
      - user
      - group

miniforge_download:
  file.managed:
    - name: /tmp/miniforge-init.sh
    - source: https://github.com/conda-forge/miniforge/releases/download/{{ miniforge_version }}/Miniforge3-Linux-{{ cpu_arch }}.sh
    - skip_verify: True
    - mkdirs: True
    - provides: /tmp/miniforge-init.sh

# Remove stale _conda symlink so -u reinstall doesn't fail on ln conflict
miniforge_clean_conda_symlink:
  file.absent:
    - name: {{ miniforge_path }}/_conda
    - require:
      - file: miniforge_directory

# Install miniforge system-wide
# -b = batch mode (non-interactive)
# -p = installation prefix
# -s = skip pre/post-link/install scripts (we handle conda init via profile.d)
# -u = update ( bypasses dir being present )
miniforge_install:
  cmd.run:
    - name: bash /tmp/miniforge-init.sh -b -u -s -p {{ miniforge_path }}
    - runas: root
    - hide_output: True
    - output_loglevel: quiet
    - order: 0
    - require:
      - file: miniforge_download
      - file: miniforge_clean_conda_symlink

# Install base pip packages via common orchestration
include:
  - common.miniforge

extend:
  conda_config:
    cmd.run:
      - require:
        - cmd: miniforge_install
