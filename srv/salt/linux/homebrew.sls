# Linux Homebrew installation with ACL-based permission management
# Uses default supported path: /home/linuxbrew/.linuxbrew
# ACL permissions allow multiple users to manage packages via cozyusers group
# Requires git and build-essential (already in packages)
# Requires acl package (for setfacl permissions)
# Note: cozyusers group created in linux.users state

{# Path configuration from pillar with defaults #}
{% set homebrew_base = salt['pillar.get']('install_paths:homebrew:linux', '/home/linuxbrew/.linuxbrew') %}
{# Extract parent directory for initial creation #}
{% set homebrew_parent = homebrew_base.rsplit('/', 1)[0] if '/' in homebrew_base else '/home/linuxbrew' %}
{# Use first managed user for homebrew operations (homebrew rejects root) #}
{# TODO: prep for service_user will be pillar service_user: buildgirl probs #}
{% set managed_users = salt['pillar.get']('managed_users', [], merge=True) %}
{% set service_user = managed_users[0] if managed_users else 'nobody' %}

# Create parent directory owned by service_user
# Homebrew installer will create .linuxbrew subdirectory
linuxbrew_directory:
  file.directory:
    - name: {{ homebrew_parent }}
    - user: {{ service_user }}
    - group: cozyusers
    - mode: "0775"
    - makedirs: True
    - order: 20

# Download and execute Homebrew installer (default supported path)
# Runs as service_user (Homebrew rejects root execution)
# NONINTERACTIVE=1 suppresses prompts
homebrew_install:
  cmd.run:
    - name: |
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    - runas: {{ service_user }}
    - env:
      - NONINTERACTIVE: 1
    - creates: {{ homebrew_base }}/bin/brew
    - require:
      - file: linuxbrew_directory

# Set ACL permissions for cozyusers group on Homebrew directories
# Allows group members to read, write, and install packages
homebrew_acl_permissions:
  cmd.run:
    - name: |
        setfacl -R -m g:cozyusers:rwx {{ homebrew_base }}
        setfacl -R -d -m g:cozyusers:rwx {{ homebrew_base }}
    - require:
      - cmd: homebrew_install

# Update Homebrew after installation (must run as non-root user)
# Fix missing git remote and safe.directory if needed, then update
homebrew_update:
  cmd.run:
    - name: |
        git config --global --add safe.directory {{ homebrew_base }}/Homebrew
        cd {{ homebrew_base }}/Homebrew
        if ! git remote get-url origin >/dev/null 2>&1; then
          git remote add origin https://github.com/Homebrew/brew.git
        fi
        {{ homebrew_base }}/bin/brew update || true
    - runas: {{ service_user }}
    - require:
      - cmd: homebrew_install
    - unless: test -f {{ homebrew_base }}/var/homebrew/.last_update_timestamp

# Install packages from provisioning/packages.sls brew list
{% import_yaml "packages.sls" as packages %}
{% set brew_packages = packages.get('brew', []) %}
{% if brew_packages %}
install_brew_packages:
  cmd.run:
    - name: {{ homebrew_base }}/bin/brew install {{ brew_packages | join(' ') }}
    - runas: {{ service_user }}
    - unless: test ! -x {{ homebrew_base }}/bin/brew
    - require:
      - cmd: homebrew_update
{% endif %}
