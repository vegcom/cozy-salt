# PowerShell Profile Configuration

Deploy PowerShell 7 system-wide profile with comprehensive configuration.

## Location

- **State**: `srv/salt/windows/profiles.sls`
- **Include**: `windows.init`

## Deploys

| File              | Purpose                               |
| ----------------- | ------------------------------------- |
| Profile.ps1       | System-wide PowerShell initialization |
| profile.d/        | Modular configuration scripts         |
| PSReadLine config | Command-line editing and history      |

## Configuration

Includes:

- Aliases for common commands
- Custom functions and utilities
- Module imports
- Tab completion setup
- History management
- Prompt customization

## Locations

Deployed to:

- `$PROFILE.AllUsersAllHosts` (all users, all hosts)
- `$env:ProgramFiles\PowerShell\7\profile.ps1`
- `C:\ProgramData\PowerShell\profile.d/`

## Integration

Profile sets up:

- NVM/Node.js paths
- Rust paths
- Conda/Miniforge
- SSH agent (if available)
- Custom utility functions

## Usage

```powershell
$PROFILE                  # Show profile path
. $PROFILE               # Reload profile
code $PROFILE            # Edit in VS Code
Get-Content $PROFILE     # View contents
```

## Notes

- Runs on every PowerShell 7 launch
- Modular design allows easy extension
- Sourced before user profile
- May slow startup if too many operations
