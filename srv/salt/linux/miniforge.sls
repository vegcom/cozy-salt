# Linux Miniforge installation and setup
# Installs miniforge to ~/.miniforge3 for conda package management

{% set user = salt['pillar.get']('user:name', 'admin') %}
{% set user_home = '/home/' ~ user if user != 'root' else '/root' %}

# Download miniforge installer
miniforge_download:
  cmd.run:
    - name: |
        curl -fsSL -o /tmp/miniforge-init.sh https://github.com/conda-forge/miniforge/releases/download/23.11.0-0/Miniforge3-Linux-x86_64.sh
    - creates: /tmp/miniforge-init.sh

# Install miniforge to ~/.miniforge3
miniforge_install:
  cmd.run:
    - name: |
        bash /tmp/miniforge-init.sh -b -p {{ user_home }}/.miniforge3
        rm -f /tmp/miniforge-init.sh
    - runas: {{ user }}
    - require:
      - cmd: miniforge_download
    - creates: {{ user_home }}/.miniforge3/bin/conda
    - env:
      - HOME: {{ user_home }}

# Initialize conda shell completion
miniforge_init:
  cmd.run:
    - name: bash -il -c "{{ user_home }}/.miniforge3/bin/conda init bash && {{ user_home }}/.miniforge3/bin/conda init zsh"
    - runas: {{ user }}
    - require:
      - cmd: miniforge_install
    - unless: grep -q "# >>> conda initialize >>>" {{ user_home }}/.bashrc
    - env:
      - HOME: {{ user_home }}
