base:
  # All minions get common states (dotfiles, nvm, etc.)
  '*':
    - common

  # All Windows systems (physical + WSL contexts)
  'os_family:Windows':
    - match: grain
    - windows

  # Debian-based Linux (Ubuntu, Debian, etc.)
  'os_family:Debian':
    - match: grain
    - linux

  # RHEL-based Linux (CentOS, Rocky, etc.)
  'os_family:RedHat':
    - match: grain
    - linux
