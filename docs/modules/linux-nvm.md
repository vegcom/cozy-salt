# NVM (Node Version Manager) - Linux

System-wide Node.js version manager installation to `/opt/nvm`.

## Location

- **State**: `srv/salt/linux/nvm.sls`
- **Include**: `linux.init`
- **Global packages**: `common.nvm`

## Installation

Installs NVM from official repo: https://github.com/nvm-sh/nvm

| Item | Location |
|------|----------|
| NVM binary | `/opt/nvm` |
| Shell init | `/etc/profile.d/nvm-init.sh` |
| Default Node | Version from `linux:nvm:default_version` pillar |

## Pillar Configuration

```yaml
nvm:
  default_version: 'lts/*'  # or 'lts/gallium', 'v18.0.0', etc.
```

## Global Packages

Installed via `common.nvm`:
- pnpm
- bun
- tsx
- npm CLI tools (webpack, create-react-app, @angular/cli, etc.)

See `docs/modules/common-nvm.md` for complete list.

## Usage

After provisioning:
```bash
nvm list              # List installed versions
nvm install 18       # Install specific version
nvm use 18           # Switch version
node --version       # Verify
```

## Notes

- Requires curl (installed via core_utils)
- Shell profile auto-sources NVM on login
- Affects all users via system-wide setup
- Different from Windows nvm-windows (separate state)
