# Windows PATH Management

Consolidated Windows PATH environment variable management via registry.

## Location

- **State**: `srv/salt/windows/paths.sls`
- **Include**: `windows.init`

## Purpose

Manages system-wide PATH via Windows registry to:

- Add tool directories (nvm, rust, miniforge, conda)
- Remove duplicates
- Maintain proper order
- Avoid PATH length limits

## Configures

Adds to PATH:

- `C:\opt\nvm` (NVM/Node.js)
- `C:\opt\rust\bin` (Rust)
- `C:\opt\miniforge3` (Conda)
- `C:\opt\miniforge3\Scripts` (Conda utilities)
- PowerShell paths

## Registry Location

Modifies:

```
HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment\Path
```

## Notes

- Registry-based (persists across reboots)
- Applied system-wide (all users)
- Changes require PowerShell restart to take effect
- CMD windows need to be restarted
- Handles duplicate path entries
