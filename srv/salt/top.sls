base:
  # All Windows (physical + WSL contexts)
  'G@os_family:Windows':
    - win.base

  # Physical-only (non-WSL)
  'G@os_family:Windows and G@is_wsl:false':
    - win.physical

  # WSL-on-Win tasks
  'G@os_family:Windows and G@is_wsl:true':
    - win.wslbase:
  # All Windows (physical + WSL contexts)
  'G@os_family:Windows':
    - win.base

  # Physical-only (non-WSL)
  'G@os_family:Windows and G@is_wsl:false':
    - win.physical

  # WSL-on-Win tasks
  'G@os_family:Windows and G@is_wsl:true':
    - win.wsl