# Linux Homebrew installation with ACL-based permission management
# Uses default supported path: /home/linuxbrew/.linuxbrew
# ACL permissions allow multiple users to manage packages via cozyusers group
# Requires git and build-essential (already in packages)
# Requires acl package (for setfacl permissions)
# Note: cozyusers group and admin user created in linux.users state

{# Path configuration from pillar with defaults #}
{% set homebrew_base = salt['pillar.get']('install_paths:homebrew:linux', '/home/linuxbrew/.linuxbrew') %}
{# Extract parent directory for initial creation #}
{% set homebrew_parent = homebrew_base.rsplit('/', 1)[0] if '/' in homebrew_base else '/home/linuxbrew' %}

# Create parent directory owned by admin user
# Homebrew installer will create .linuxbrew subdirectory
linuxbrew_directory:
  file.directory:
    - name: {{ homebrew_parent }}
    - user: admin
    - group: admin
    - mode: 755
    - makedirs: True
    - order: 20
    - require:
      - user: admin_user
      - group: cozyusers_group

# Download and execute Homebrew installer (default supported path)
# Runs as admin user (Homebrew rejects root execution)
# NONINTERACTIVE=1 suppresses prompts
homebrew_install:
  cmd.run:
    - name: |
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    - runas: admin
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

# Deploy profile.d script for system-wide brew initialization
homebrew_profile:
  file.managed:
    - name: /etc/profile.d/homebrew.sh
    - source: salt://linux/files/etc-profile.d/homebrew.sh
    - mode: 644
    - require:
      - cmd: homebrew_acl_permissions

# Update Homebrew after installation (must run as admin, not root)
# Fix missing git remote if needed, then update
homebrew_update:
  cmd.run:
    - name: |
        cd {{ homebrew_base }}/Homebrew
        if ! git remote get-url origin >/dev/null 2>&1; then
          git remote add origin https://github.com/Homebrew/brew.git
        fi
        {{ homebrew_base }}/bin/brew update || true
    - runas: admin
    - require:
      - cmd: homebrew_install
    - unless: test -f {{ homebrew_base }}/var/homebrew/.last_update_timestamp
