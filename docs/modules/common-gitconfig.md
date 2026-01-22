# Git Configuration Deployment

Deploy dotfiles for git configuration: .gitconfig, .git-credentials, .gitignore_global.

## Location

- **State**: `srv/salt/common/gitconfig.sls`
- **Include**: `common.init`

## Deploys

| File | Purpose |
|------|---------|
| `.gitconfig` | Git configuration (user.name, user.email, aliases, core settings) |
| `.git-credentials` | Stored credentials for HTTPS auth (sensitive) |
| `.gitignore_global` | Global gitignore patterns |

## Source Files

From `provisioning/common/`:
- `.gitconfig.jinja` (templated with pillar values)
- `.git-credentials` (if exists)
- `.gitignore_global`

## Pillar Integration

Interpolates from pillar:
- git.name, git.email (via jinja template)
- Any custom aliases or config values

## Permissions

```
.gitconfig: 644 (world-readable)
.git-credentials: 600 (user-only, sensitive)
.gitignore_global: 644
```

## Usage

```bash
git config --list        # View all config
git config --global -e   # Edit in editor
git config user.name     # Get specific value
```

## Notes

- Cross-platform (Linux, Windows, macOS)
- Credentials file optional (only deployed if exists)
- Global patterns prevent committing common junk files
