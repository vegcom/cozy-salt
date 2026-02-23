#!jinja|yaml
# Example User Configuration
# Copy this file and rename to {username}.sls (e.g., newuser.sls)
# Each user gets their own file in srv/pillar/users/

{% set docker_enabled = salt['pillar.get']('docker_enabled', False) %}

users:
  example_user:
    fullname: Example User
    shell: /bin/bash
    home_prefix: /home
    # UID/GID for SMB/NFS consistency (start at 3000+)
    # uid: 3004
    # gid: 3004
    # SMB credentials (for shared mounts defined in common/users.sls)
    # smb_password: supersecret
    # smb_username: example_user  # optional, defaults to username
    # smb_domain: WORKGROUP       # optional
    linux_groups:
      - cozyusers
      - libvirt
      - kvm
{% if docker_enabled %}
      - docker
{% endif %}
    windows_groups:
      - Administrators
      - Users
      - cozyusers
    ssh_keys:
      # Add public SSH keys for remote access
      - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIxxxxxxxxxxxx...your-public-key
    password: "demo_PlzChange"
    github:
      # Email and name auto-deployed to .gitconfig.local [user] section
      email: user+github@example.com
      name: Example User
      # Personal access tokens for private repo cloning
      # These merge with global tokens from common/users.sls
      tokens:
        - ghp_example_token_xyz123
