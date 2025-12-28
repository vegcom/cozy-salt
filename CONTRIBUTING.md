# Contributing to cozy-salt

Thank you for contributing! This guide will help you set up your development environment and understand the project structure.

## Development Setup

### Prerequisites
- Docker and Docker Compose
- Git
- For WSL development: WSL2 with Ubuntu 22.04+
- For Windows testing: Windows 10/11 with PowerShell

### Quick Start for Development

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd cozy-salt
   ```

2. **Start the Salt Master:**
   ```bash
   docker compose up -d
   ```

3. **Test with a Linux minion:**
   ```bash
   docker compose --profile test-linux up -d
   docker exec salt-master salt '*' test.ping
   ```

## Architecture Philosophy

The project follows a clear separation of concerns:

- **srv/salt/** - Orchestration ONLY (import packages, deploy files, manage services)
- **provisioning/** - All files to deploy + consolidated package list
- **srv/pillar/** - Configuration data (no logic)
- **States should NOT hardcode packages** - Always import from `packages.sls`

### Design Principles

1. **Modularity**: Each state module (packages, config, tasks, services) can be applied independently
2. **No Duplication**: Packages defined once in `provisioning/packages.sls`, imported everywhere
3. **Orchestration vs Files**: State files orchestrate, provisioning files are deployed
4. **Platform Agnostic**: Same structure for Windows and Linux (init.sls + modules)

### File Path Mapping

| Local Path | Salt Path | Description |
|------------|-----------|-------------|
| `srv/salt/` | `salt://` | State files |
| `srv/pillar/` | (pillar data) | Configuration values |
| `provisioning/` | `salt://` (via file_roots) | Deployed files + packages.sls |

The Salt Master is configured with multiple file_roots (see `srv/master.d/file_roots.conf`):
- `/srv/salt` - Primary state files
- `/srv/provisioning` - Platform-specific files and packages.sls

**Examples:**
- `provisioning/windows/files/opt-cozy/win.ps1` → `salt://windows/files/opt-cozy/win.ps1`
- `provisioning/packages.sls` → `salt://packages.sls`

## Project Structure

```
cozy-salt/
├── srv/
│   ├── salt/                   # Salt state tree (orchestration only)
│   │   ├── top.sls             # Highstate mapping
│   │   ├── windows/
│   │   │   ├── init.sls        # Windows orchestrator
│   │   │   ├── packages.sls    # Package installation
│   │   │   ├── config.sls      # Configuration
│   │   │   ├── tasks.sls       # Scheduled tasks
│   │   │   └── services.sls    # Service management
│   │   └── linux/
│   │       ├── init.sls        # Linux orchestrator
│   │       ├── packages.sls    # Package installation
│   │       ├── config.sls      # Configuration
│   │       └── services.sls    # Service management
│   ├── pillar/                 # Pillar data tree
│   │   ├── top.sls             # Pillar mapping
│   │   ├── win/init.sls        # Windows pillar data
│   │   └── linux/init.sls      # Linux pillar data
│   └── master.d/               # Salt Master config overrides
│       ├── file_roots.conf     # Adds /srv/provisioning to file_roots
│       └── auto_accept.conf.example  # Auto-accept keys (testing only)
├── provisioning/               # Platform-specific files (mounted at /srv/provisioning)
│   ├── packages.sls            # CONSOLIDATED package list (apt, dnf, choco, winget)
│   ├── windows/                # Windows setup files
│   ├── linux/                  # Linux setup files
│   └── wsl/                    # WSL-specific files
├── scripts/
│   ├── install-win-minion.ps1  # Windows minion installer
│   ├── entrypoint-master.sh    # Salt Master entrypoint
│   └── entrypoint-minion.sh    # Test minion entrypoint
├── tests/
│   └── (future unit/integration tests)
├── Dockerfile.master           # Salt Master image
├── Dockerfile.linux-minion     # Test minion image
└── docker-compose.yaml         # Compose with profiles (master + test minions)
```

## File Permissions

**IMPORTANT:** Salt runs as user `salt` (uid 999) inside the container. All mounted files must be readable.

After creating new state files, fix permissions:

```bash
# Fix permissions on all Salt directories
find srv/salt srv/pillar provisioning -type d -exec chmod 755 {} \;
find srv/salt srv/pillar provisioning -type f -exec chmod 644 {} \;
```

- Directories need `755` (rwxr-xr-x) so Salt can traverse them
- Files need `644` (rw-r--r--) so Salt can read them

## Testing

### Test Individual Modules

The modular state structure allows testing individual components:

```powershell
# Windows
salt-call state.apply windows           # Everything
salt-call state.apply windows.packages  # Just packages
salt-call state.apply windows.tasks     # Just scheduled tasks
salt-call state.apply windows.config    # Just configuration
salt-call state.apply windows.services  # Just services
```

```bash
# Linux
salt-call state.apply linux             # Everything
salt-call state.apply linux.packages    # Just packages
salt-call state.apply linux.config      # Just configuration
salt-call state.apply linux.services    # Just services
```

### Test with Docker Minions

```bash
# Linux test minion
docker compose --profile test-linux up -d
docker exec salt-master salt '*' test.ping
docker exec salt-master salt '*' state.apply

# Cleanup
docker compose --profile test-linux down
```

### Testing Changes

1. Make changes to state files
2. Fix permissions: `find srv/salt -type f -exec chmod 644 {} \;`
3. Test with minion: `salt-call state.apply <module>`
4. Check for errors and iterate

## Adding Packages

### Add a New Package

1. **Edit `provisioning/packages.sls`:**
   ```yaml
   choco:
     - existing-package
     - your-new-package  # Add here

   apt:
     - existing-package
     - your-new-package  # Add here
   ```

2. **States automatically pick it up** via `{% import_yaml 'packages.sls' as packages %}`

3. **Test:**
   ```powershell
   salt-call state.apply windows.packages
   ```

### Package List Structure

- `choco` - Chocolatey packages (Windows)
- `winget` - Winget packages (Windows, prefer choco when available)
- `winget_runtimes` - Winget runtime libraries (Windows)
- `winget_msstore` - Microsoft Store apps via Winget (Windows)
- `apt` - APT packages (Debian/Ubuntu)
- `dnf` - DNF packages (RHEL/Fedora)

## Creating New States

### 1. Create the State File

Create a new `.sls` file in the appropriate directory:

```yaml
# srv/salt/windows/myfeature.sls
myfeature_config:
  file.managed:
    - name: C:\config\myfeature.conf
    - source: salt://windows/files/myfeature.conf
    - makedirs: True
```

### 2. Include in Orchestrator

Add to `init.sls`:

```yaml
# srv/salt/windows/init.sls
include:
  - windows.packages
  - windows.config
  - windows.tasks
  - windows.services
  - windows.myfeature  # Add here
```

### 3. Fix Permissions

```bash
chmod 644 srv/salt/windows/myfeature.sls
```

### 4. Test

```powershell
salt-call state.apply windows.myfeature
```

## Code Style

### State Files

- **Orchestration only** - No hardcoded package lists
- **Import packages** from `packages.sls`
- **Use pillar data** for configuration values
- **File references** use `salt://` URIs
- **Comments** explain the "why", not the "what"

### Naming Conventions

**TODO:** This section needs standardization. Current issues:
- Files use mixed naming (dashes, underscores, spaces)
- Jinja2 templates have excessive `replace()` calls
- State IDs don't match file names

**Proposed standard:**
- Files: `lowercase_underscore.xml`
- State IDs: Same as filename without extension
- Display names: Transform only when needed for UI

### File Organization

- **srv/salt/** - State files (orchestration)
- **provisioning/** - Files to deploy + consolidated packages
- **srv/pillar/** - Configuration data
- **scripts/** - Helper scripts for setup

## Pillar Data

### Windows (`srv/pillar/win/init.sls`)
```yaml
cozy:
  base_path: 'C:\opt\cozy'
docker:
  context_name: wsl
  host: tcp://127.0.0.1:2375
packages:
  manager: chocolatey
```

### Linux (`srv/pillar/linux/init.sls`)
```yaml
cozy:
  base_path: '/opt/cozy'
ssh:
  port: 2222
shell:
  prompt: starship
```

## Troubleshooting

### "No matching sls found"

Check file permissions:
```bash
docker exec salt-master ls -la /srv/salt/windows/
```

If permissions are wrong (not readable), fix them:
```bash
find srv/salt -type f -exec chmod 644 {} \;
```

### "State not found in SLS"

- Verify the function name exists (e.g., `task.present` not `win_task.present`)
- Check module is available: `salt-call sys.list_state_modules | grep task`

### Changes Not Applying

1. Check if file is mounted correctly:
   ```bash
   docker exec salt-master cat /srv/salt/windows/tasks.sls
   ```

2. Restart the master if needed:
   ```bash
   docker compose restart salt-master
   sleep 15  # Wait for restart
   ```

3. Clear minion cache:
   ```powershell
   salt-call saltutil.clear_cache
   ```

## Git Workflow

1. Create a branch for your feature
2. Make changes
3. Fix permissions
4. Test thoroughly
5. Commit with clear messages:
   ```bash
   git add .
   git commit -m "Add feature: description

   - Specific change 1
   - Specific change 2

   🤖 Generated with Claude Code

   Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
   ```
6. Push and create a pull request

## Security Considerations

- **Never commit secrets** - Use pillar data or environment variables
- **Auto-accept keys** is for testing only - disable in production
- **Review SECURITY.md** before deploying to production
- **Default passwords** - Always change before deployment (especially PXE)

## Questions?

- Check CLAUDE.md for AI assistant guidance
- See README.md for user documentation
- See SECURITY.md for security considerations
