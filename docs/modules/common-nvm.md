# NVM Global Package Installation

Cross-platform global npm package installation after NVM setup.

## Location

- **State**: `srv/salt/common/nvm.sls`
- **Include**: `common.init`

## Installs Globally

Global npm packages available in all projects:

| Package | Purpose |
|---------|---------|
| pnpm | Fast npm alternative |
| bun | Fast JavaScript runtime |
| tsx | TypeScript executor |
| @angular/cli | Angular CLI tools |
| @nestjs/cli | NestJS framework CLI |
| @vue/cli | Vue framework CLI |
| create-react-app | React project scaffold |
| webpack | Module bundler |
| nodemon | Auto-restart on file change |
| pm2 | Process manager for Node apps |
| serverless | Serverless framework |
| cdk | AWS CDK CLI |

## Usage

```bash
npm list -g           # List global packages
npm install -g pkg    # Install globally
tsx script.ts         # Run TypeScript directly
```

## Platform Support

- **Linux**: Via `/opt/nvm/bin/npm` (after nvm-init.sh)
- **Windows**: Via Windows nvm-windows npm

## Notes

- Requires NVM installation first (linux.nvm or windows.nvm)
- Installs to NVM's global directory (~/.npm-global or %APPDATA%)
- Must run after NVM setup completes
- Packages available in PATH for all users
