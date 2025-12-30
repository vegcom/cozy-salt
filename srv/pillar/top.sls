base:
  # All systems get common configuration
  '*':
    - common.network
    - common.paths
    - common.versions

  # Windows systems
  'G@os_family:Windows':
    - match: compound
    - win

  # Linux systems
  'G@os_family:Debian or G@os_family:RedHat':
    - match: compound
    - linux