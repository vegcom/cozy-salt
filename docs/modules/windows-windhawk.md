# Windhawk Installation

Windows customization tool for modifying system behavior without patching core files.

## Location

- **State**: `srv/salt/windows/windhawk.sls`
- **Include**: `windows.init`

## Purpose

Windhawk allows system modifications:
- Window management customization
- Taskbar modifications
- Explorer/shell tweaks
- Theme and visual customization

## Installation

Installs Windhawk from official source:
https://ramensoftware.com/windows-customization-windhawk

| Item | Details |
|------|---------|
| Binary | `C:\Program Files\Windhawk\` |
| Service | Windhawk engine runs as service |
| Mods | Downloaded from Windhawk mod store |

## Pillar Configuration

```yaml
windhawk:
  version: latest
  auto_update: true
  mods:
    - windows-11-taskbar-grouping
    - taskbar-thumbnail-reorder
```

## Common Mods

- **Windows 11 Taskbar Grouping**: Group similar windows
- **Taskbar Thumbnail Reorder**: Reorder grouped apps
- **Explorer Customization**: Modify file explorer behavior
- **Window Snapping**: Enhanced window management

## Usage

Windhawk automatically applies enabled mods:
- Settings app: Configure mods
- Engine auto-updates
- Mods reload on changes

## Notes

- Requires Windows 10+ (20H2) or Windows 11
- Portable executable (easy to uninstall)
- Service runs at system level
- Mods community-maintained
- No system files modified (safe)
