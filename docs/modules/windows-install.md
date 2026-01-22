# Windows Package Installation

Windows package installation via WinGet with bootstrap logic for dependencies.

## Location

- **State**: `srv/salt/windows/install.sls`
- **Include**: `windows.init`

## Installation Order

1. **Runtimes** (`winget_runtimes`): VCRedist, .NET, UI libraries first
2. **System Packages** (`winget_system`): Development tools, terminals, sync tools
3. **User Packages** (`winget_userland`): Applications, utilities, games
4. **Fallback**: Chocolatey for packages WinGet doesn't have

## Package Groups

| Group | Examples |
|-------|----------|
| UI Libraries | Microsoft.UI.Xaml, Microsoft.VCLibs |
| VCRedist | 2008-2015+ Visual C++ runtimes |
| SDKs | Windows ADK, Windows SDK, NuGet |
| .NET | AspNetCore, DesktopRuntime 8/9/10 |
| System | PowerShell, Git, Windows Terminal |
| Dev | Visual Studio, VS Code, IntelliJ, GitHub Desktop |
| User | Discord, Firefox, Steam, qBittorrent |

## Pillar Configuration

```yaml
winget:
  install_runtimes: true
  install_system: true
  install_userland: false  # Optional
```

## Notes

- WinGet requires Windows 10+ and Store app
- Fallback to Chocolatey for missing packages
- Requires admin privileges
- Installation order matters (runtimes before apps)
- See provisioning/packages.sls for full list
