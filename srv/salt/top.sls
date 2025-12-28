base:
  # All Windows systems (physical + WSL contexts)
  'os_family:Windows':
    - match: grain
    - windows.win

  # Debian-based Linux (Ubuntu, Debian, etc.)
  'os_family:Debian':
    - match: grain
    - linux.base

  # RHEL-based Linux (CentOS, Rocky, etc.)
  'os_family:RedHat':
    - match: grain
    - linux.base
