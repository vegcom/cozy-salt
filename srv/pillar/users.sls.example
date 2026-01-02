# Shared user definitions across all platforms
# Included by both linux and win pillars

users:
  admin:
    fullname: Admin User
    shell: /bin/bash
    home_prefix: /home
    linux_groups:
      - cozyusers
      - docker
    windows_groups:
      - Administrators
      - Users

  vegcom:
    fullname: Vegcom User
    shell: /bin/bash
    home_prefix: /home
    linux_groups:
      - cozyusers
      - docker
    windows_groups:
      - Users

  eve:
    fullname: Eve User
    shell: /bin/bash
    home_prefix: /home
    linux_groups:
      - cozyusers
      - docker
    windows_groups:
      - Users

# Managed users list for dotfiles/resource management
managed_users:
  - admin
  - vegcom
  - eve
