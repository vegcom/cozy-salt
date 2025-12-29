# Linux Homebrew installation and setup
# Installs Homebrew to ~/.linuxbrew for user-level package management
# Requires git and build-essential (already in packages)

{% set user = salt['pillar.get']('user:name', 'admin') %}
{% set user_home = '/home/' ~ user if user != 'root' else '/root' %}

# Download and execute Homebrew installer
homebrew_install:
  cmd.run:
    - name: |
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    - runas: {{ user }}
    - creates: {{ user_home }}/.linuxbrew/bin/brew
    - env:
      - HOME: {{ user_home }}

# Update Homebrew after installation
homebrew_update:
  cmd.run:
    - name: bash -il -c "{{ user_home }}/.linuxbrew/bin/brew update"
    - runas: {{ user }}
    - require:
      - cmd: homebrew_install
    - unless: test -f {{ user_home }}/.linuxbrew/bin/brew && test -f {{ user_home }}/.linuxbrew/var/homebrew/.last_update_timestamp
    - env:
      - HOME: {{ user_home }}
