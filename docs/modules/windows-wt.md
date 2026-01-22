# Windows Terminal Installation

Modern terminal emulator for Windows with PowerShell, CMD, and WSL integration.

## Location

- **State**: `srv/salt/windows/wt.sls`
- **Include**: `windows.init`

## Installation

Installs Windows Terminal from Microsoft Store or WinGet.

| Item    | Location                                                                       |
| ------- | ------------------------------------------------------------------------------ |
| Binary  | `C:\Program Files\WindowsTerminal\`                                            |
| Config  | `%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_*/LocalState/settings.json` |
| Symlink | Optional start menu shortcut                                                   |

## Features

- Multiple profiles (PowerShell, CMD, WSL, Git Bash)
- Tabs and panes
- Custom color schemes
- Font configuration
- Unicode/emoji support

## Configuration

Deployed via JSON settings:

- Default profile selection
- Tab behavior
- Color schemes
- Keyboard shortcuts
- Font families

## Profiles Available

- PowerShell 7
- Command Prompt
- WSL (if installed)
- Git Bash (if Git installed)
- Azure Cloud Shell

## Usage

```cmd
wt                    REM Open Windows Terminal
wt -d C:\             REM Open in specific directory
wt -p "PowerShell"    REM Open specific profile
```

## Notes

- Requires Windows 10 1903+ or Windows 11
- Can be default terminal (Windows 11)
- Configuration syncs across installations
- Supports custom color schemes and themes
