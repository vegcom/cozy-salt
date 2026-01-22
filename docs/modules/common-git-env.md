# Git Environment Variables

Deploy GIT_NAME and GIT_EMAIL environment variables to shell profiles.

## Location

- **State**: `srv/salt/common/git_env.sls`
- **Include**: `common.init`

## Deploys

Creates shell profile scripts that export:

```bash
export GIT_NAME="Your Name"
export GIT_EMAIL="email@example.com"
```

## Pillar Configuration

Requires pillar data (no defaults):

```yaml
git:
  name: "John Doe"
  email: "john@example.com"
```

## Effect

Variables available in:

- Shell sessions (bash, zsh, sh)
- Git commits (used by git-commit hook)
- SSH identity (can be used in .gitconfig)

## Notes

- Deployed to `/etc/profile.d/git-env.sh`
- Cross-platform (Linux and Windows)
- No-op if pillar data missing
- Values interpolated at provisioning time (static)
