base:
  # Windows systems
  'G@os_family:Windows':
    - match: compound
    - win

  # Linux systems
  'G@os_family:Debian or G@os_family:RedHat':
    - match: compound
    - linux