# Windows User Management

Windows user creation and group configuration.

## Location

- **State**: `srv/salt/windows/users.sls`
- **Include**: `windows.init`

## Creates

| Item | Details |
|------|---------|
| User | Dynamic from `windows:user:name` pillar |
| Groups | Adds user to: Administrators, Users, Remote Desktop |
| Home directory | C:\Users\{username} with proper permissions |
| Profile | User profile initialization |

## Pillar Configuration

```yaml
user:
  name: Administrator  # or your preferred user
```

## Auto-Detection

If not specified, uses:
1. %USERNAME% environment variable
2. Falls back to Administrator

## Group Membership

Adds user to:
- Administrators: Full system access
- Remote Desktop Users: RDP access (optional)
- docker: Docker API access (if installed)

## Notes

- Runs early in windows.init (before other states)
- Changes require sign-out/sign-in to take effect
- Home directory created automatically by Windows
- User must exist or be created by state
