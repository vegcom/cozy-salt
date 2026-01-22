# NVM (Node Version Manager) - Windows

Node.js version manager installation to `C:\opt\nvm` on Windows.

## Location

- **State**: `srv/salt/windows/nvm.sls`
- **Include**: `windows.init`
- **Global packages**: `common.nvm`

## Installation

Installs nvm-windows (Windows-specific):
<https://github.com/coreybutler/nvm-windows>

| Item          | Location                                  |
| ------------- | ----------------------------------------- |
| NVM binary    | `C:\opt\nvm`                              |
| Node versions | `C:\opt\nvm\versions\node`                |
| Default Node  | From `windows:nvm:default_version` pillar |

## Pillar Configuration

```yaml
nvm:
  default_version: "lts" # or 'lts/gallium', '18.0.0', etc.
```

## Global Packages

Installed via `common.nvm`:

- pnpm, bun, tsx
- @angular/cli, @nestjs/cli, @vue/cli
- create-react-app, webpack, nodemon, pm2, serverless, cdk

## Usage

```cmd
nvm list              REM List installed versions
nvm install 18       REM Install specific version
nvm use 18           REM Switch version
node --version       REM Verify
```

## Notes

- Different from Linux nvm (nvm-windows vs nvm)
- PATH auto-configured by installer
- Affects all users on system
- Different release cycle than Linux nvm
