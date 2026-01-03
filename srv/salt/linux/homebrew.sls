# Linux Homebrew installation with ACL-based permission management
# Uses default supported path: /home/linuxbrew/.linuxbrew
# ACL permissions allow multiple users to manage packages via cozyusers group
# Requires git and build-essential (already in packages)
# Requires acl package (for setfacl permissions)
# Note: cozyusers group and admin user created in linux.users state

# Create /home/linuxbrew directory owned by admin user
# Homebrew installer will create .linuxbrew subdirectory
linuxbrew_directory:
  file.directory:
    - name: /home/linuxbrew
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
    - creates: /home/linuxbrew/.linuxbrew/bin/brew
    - require:
      - file: linuxbrew_directory

# Set ACL permissions for cozyusers group on Homebrew directories
# Allows group members to read, write, and install packages
homebrew_acl_permissions:
  cmd.run:
    - name: |
        setfacl -R -m g:cozyusers:rwx /home/linuxbrew/.linuxbrew
        setfacl -R -d -m g:cozyusers:rwx /home/linuxbrew/.linuxbrew
    - require:
      - cmd: homebrew_install

# Deploy profile.d script for system-wide brew initialization
homebrew_profile:
  file.managed:
    - name: /etc/profile.d/homebrew.sh
    - source: salt://provisioning/linux/files/etc-profile.d/homebrew.sh
    - mode: 644
    - require:
      - cmd: homebrew_acl_permissions

# Update Homebrew after installation (must run as admin, not root)
# Fix missing git remote if needed, then update
homebrew_update:
  cmd.run:
    - name: |
        cd /home/linuxbrew/.linuxbrew/Homebrew
        if ! git remote get-url origin >/dev/null 2>&1; then
          git remote add origin https://github.com/Homebrew/brew.git
        fi
        /home/linuxbrew/.linuxbrew/bin/brew update || true
    - runas: admin
    - require:
      - cmd: homebrew_install
    - unless: test -f /home/linuxbrew/.linuxbrew/var/homebrew/.last_update_timestamp
