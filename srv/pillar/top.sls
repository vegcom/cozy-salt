base:
  # All systems get common configuration
  '*':
    - common.users
    - common.network
    - common.paths
    - common.versions

  # Windows systems
  'G@os_family:Windows':
    - match: compound
    - windows

  # Linux systems
  'G@os_family:Debian or G@os_family:RedHat':
    - match: compound
    - linux

  # Hardware class: Valve Galileo (Steam Deck)
  # Detection: Check minion ID or hostname
  'guava':
    - class.galileo
    - host.guava