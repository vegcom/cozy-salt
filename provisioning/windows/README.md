# Windows Provisioning Files

This directory contains Windows-specific provisioning files deployed by Salt states. These files configure system-wide PowerShell, initial setup, and automation tasks.

## Directory Structure

```
provisioning/windows/
├── Autounattend.xml              Windows 11 unattended setup configuration
├── files/
│   ├── opt-cozy/                 Post-install system utilities
│   │   ├── configure-docker-wsl-context.ps1
│   │   └── enable-openssh.ps1
│   └── PROFILE.AllUsersCurrentHost/  PowerShell 7 system-wide profile
│       ├── Microsoft.PowerShell_profile.ps1  Main loader
│       ├── starship.toml          Shell prompt configuration
│       └── config.d/              Modular configuration scripts
│           ├── init.ps1           Logging framework
│           ├── time.ps1           Timing utilities
│           ├── functions.ps1      Utility functions
│           ├── aliases.ps1        Command aliases
│           ├── modules.ps1        PowerShell module loader
│           ├── choco.ps1          Chocolatey integration
│           ├── code.ps1           VS Code integration
│           ├── conda.ps1          Conda/Miniforge integration
│           ├── npm.ps1            NPM/NVM integration
│           └── starship.ps1       Starship prompt
└── tasks/                         Scheduled task definitions (XML)
    ├── wsl/
    │   └── wsl_autostart.xml      WSL distro autostart task
    └── kubernetes/
        ├── docker_registry_port_forward.xml
        ├── ollama_port_forward.xml
        └── open_webui_port_forward.xml
```

## Deployment Architecture

### File Deployment Targets

| Source File                           | Deployment Target                             | Permission       | Deployed By         |
| ------------------------------------- | --------------------------------------------- | ---------------- | ------------------- |
| `files/PROFILE.AllUsersCurrentHost/*` | `C:\Program Files\PowerShell\7\*`             | 644 (readable)   | `windows.profiles`  |
| `files/opt-cozy/*.ps1`                | `C:\opt\cozy\*`                               | 755 (executable) | `windows.opt-cozy`  |
| `tasks/wsl/*.xml`                     | `C:\Windows\System32\tasks\cozy\*`            | 644 (readable)   | `windows.tasks.wsl` |
| `tasks/kubernetes/*.xml`              | `C:\Windows\System32\tasks\cozy\kubernetes\*` | 644 (readable)   | `windows.tasks.k8s` |
| `Autounattend.xml`                    | Mounted at Windows boot (Dockur)              | N/A              | Dockur VM setup     |

### Salt States for Deployment

Located in `srv/salt/windows/`:

- **`windows/profiles.sls`** → Deploys PowerShell profile files recursively
  - Creates `C:\Program Files\PowerShell\7` directory
  - Recursively copies all files from `salt://windows/files/PROFILE.AllUsersCurrentHost/`
  - Sets Windows ACLs (Users:Read, Administrators:Full)
  - Dependency for other states that modify profile

- **`windows/opt-cozy.sls`** → Deploys post-install utilities
  - Deploys `configure-docker-wsl-context.ps1` for Docker setup
  - Deploys `enable-openssh.ps1` for SSH service setup

- **`windows/tasks.wsl.sls`** → Deploys WSL automation tasks
  - `wsl_autostart.xml` → Automatically starts WSL distros on user login

- **`windows/tasks.kubernetes.sls`** → Deploys Kubernetes-related port forwarding
  - Docker registry port forwarding (localhost:5000)
  - Ollama LLM service port forwarding
  - Open WebUI service port forwarding

### Deployment Flow

```
Salt Master (Linux Docker)
    ↓ (via salt-minion)
Windows Target System
    ↓ (file.recurse / file.managed)
C:\Program Files\PowerShell\7\
C:\opt\cozy\
C:\Windows\System32\tasks\cozy\
```

Salt mounts `provisioning/windows/` at `/provisioning` in master container, which resolves to `salt://windows/` in state files.

## PowerShell Profile System

### Overview

The PowerShell profile is modular and composable, allowing independent configuration of different tools while maintaining a single entry point.

**Profile entry point**: `Microsoft.PowerShell_profile.ps1`

- **Location**: `C:\Program Files\PowerShell\7\profile.ps1` (deployed)
- **Purpose**: Main profile loader that sources all config files
- **Runs on**: Every PowerShell session start
- **Load time**: ~2-3 seconds for full initialization

### Load Order (Critical)

Config files load in this specific order in `Microsoft.PowerShell_profile.ps1`:

1. **`init.ps1`** - Logging framework & utility functions
   - Must be first (provides `logging` function used by others)
   - Provides: `logging`, `Script-Loader`, `To-Bool` functions
   - Size: 79 lines

2. **`time.ps1`** - Timing utilities
   - Provides: `Mark-Time`, `Show-Elapsed` functions
   - Used internally by profile loader
   - Size: 56 lines

3. **Remaining config files** (order doesn't matter):
   - `functions.ps1` - Utility functions
   - `aliases.ps1` - Command aliases
   - `modules.ps1` - PowerShell module imports (Terminal-Icons, PSReadLine, etc.)
   - `choco.ps1` - Chocolatey integration
   - `code.ps1` - VS Code shell integration
   - `conda.ps1` - Miniforge/Conda initialization
   - `npm.ps1` - NPM/NVM environment setup
   - `starship.ps1` - Starship prompt configuration

### Module Pattern: config.d/

Each tool/service has its own configuration file in `config.d/`:

```
config.d/
├── init.ps1          [CORE] Logging framework
├── time.ps1          [CORE] Timing utilities
├── functions.ps1     [UTILS] Shared functions
├── aliases.ps1       [UTILS] Command aliases
├── modules.ps1       [TOOLS] PowerShell modules
├── choco.ps1         [TOOLS] Chocolatey
├── code.ps1          [TOOLS] VS Code
├── conda.ps1         [TOOLS] Conda/Miniforge
├── npm.ps1           [TOOLS] NPM/NVM
└── starship.ps1      [TOOLS] Starship prompt
```

**Benefits**:

- Each tool can be enabled/disabled independently
- Changes to one tool don't affect others
- Easy to add new tools (create new config.d/tool.ps1 file)
- Logging framework available to all (if init.ps1 loads first)

### Script-Loader Function

The `Script-Loader` function in `init.ps1` handles sourcing all config files:

```powershell
function Script-Loader {
    param([Parameter(Position=0)][array]$scripts)
    foreach ($script in $scripts) {
        if (Test-Path $script) {
            Mark-Time "$script"
            . $script
            Show-Elapsed "$script" -Clear
            if (-not $?) {
                logging "load failed $script" "WARN"
            } else {
                logging "load passed $script" "DEBUG"
            }
        }
    }
}
```

Features:

- Times each script load (via `Mark-Time` / `Show-Elapsed`)
- Catches failures and logs them
- Uses PowerShell success indicator `$?` (not `$LASTEXITCODE`)
- Continues even if individual scripts fail (fault-tolerant)

### Error Handling

All config files have try/catch wrappers:

**`modules.ps1`** - Handles module import failures

```powershell
try {
    Import-Module -Scope Global -Force -Name $module -ErrorAction Stop
} catch {
    if ($_.Exception.Message -match "already registered|already imported|FeedbackProvider") {
        logging "Module $module already loaded, skipping" "DEBUG"
    } else {
        logging "Failed to import $module - $_" "WARN"
    }
}
```

**`npm.ps1`** - Handles npm detection failures

```powershell
try {
    $found = @(); [npm detection logic]
    $env:NPM_EXE = $found[0]
} catch {
    logging "Failed to initialize npm: $_" "WARN"
}
```

**`choco.ps1`** - Handles chocolatey initialization failures

```powershell
try {
    Import-Module $chocolateyprofile
} catch {
    logging "Failed to initialize chocolatey: $_" "WARN"
}
```

Profile continues even if any tool fails to initialize.

## Autounattend.xml

**Purpose**: Unattended Windows 11 setup for Dockur virtualization

**Features**:

- Accepts Windows EULA
- Sets regional/language preferences
- Configures network (DHCP)
- Runs FirstLogonCommands (executes enrollment script at first login)

**FirstLogonCommands**:

- Runs `entrypoint-minion.ps1` as SYSTEM during first boot
- Script waits for network/master, installs Salt, applies highstate
- See: `scripts/docker/entrypoint-minion.ps1`

**Usage**: Mounted in Dockur VM, automatically processed at installation time

**Not used for**: Manual Windows deployments (use `install-windows-minion.ps1` instead)

## opt-cozy Utilities

Post-installation utilities in `provisioning/windows/files/opt-cozy/`:

### configure-docker-wsl-context.ps1

**Purpose**: Configure Docker to use WSL context in Windows

**What it does**:

- Detects WSL 2 installation
- Creates Docker context pointing to WSL
- Enables efficient container development from Windows

**Deployment**: Copied to `C:\opt\cozy\`
**Executed by**: Manual run or Salt orchestration
**Requirements**: Docker Desktop installed, WSL 2 available

### enable-openssh.ps1

**Purpose**: Enable and configure Windows OpenSSH service

**What it does**:

- Installs OpenSSH server (if not present)
- Enables and starts SSH service
- Configures automatic startup

**Deployment**: Copied to `C:\opt\cozy\`
**Executed by**: Manual run or Salt orchestration
**Use case**: Remote management and CI/CD access

## Scheduled Tasks

### WSL Automation

**`tasks/wsl/wsl_autostart.xml`**

- **Task name**: `cozy\wsl-autostart`
- **Trigger**: At user logon
- **Action**: Runs `wsl --list -v` and starts distributions
- **Purpose**: Automatically start WSL distros on Windows login
- **Deployed to**: `C:\Windows\System32\tasks\cozy\`

### Kubernetes/Service Port Forwarding

Scheduled tasks for development environment automation:

**`tasks/kubernetes/docker_registry_port_forward.xml`**

- **Task name**: `cozy\kubernetes\docker-registry-pf`
- **Trigger**: At system startup
- **Action**: Forward localhost:5000 to registry service
- **Purpose**: Local Docker image registry access

**`tasks/kubernetes/ollama_port_forward.xml`**

- **Task name**: `cozy\kubernetes\ollama-pf`
- **Trigger**: At system startup
- **Action**: Forward localhost:11434 to Ollama service
- **Purpose**: Local LLM inference access

**`tasks/kubernetes/open_webui_port_forward.xml`**

- **Task name**: `cozy\kubernetes\open-webui-pf`
- **Trigger**: At system startup
- **Action**: Forward localhost:8080 to Open WebUI service
- **Purpose**: Local LLM web interface access

**All tasks**:

- Deploy to: `C:\Windows\System32\tasks\cozy\kubernetes\`
- Run with: SYSTEM privileges
- Deployed by: `windows.tasks.kubernetes` Salt state

## File Permissions

### Deployment Permissions

Files are deployed with these permissions:

| Type                              | Permission | Reason                             |
| --------------------------------- | ---------- | ---------------------------------- |
| Profile files (.ps1 in config.d/) | 644        | Sourced by profile, not executable |
| opt-cozy scripts (.ps1)           | 755        | Executable utilities               |
| Task XMLs (.xml)                  | 644        | Configuration, not executable      |
| Autounattend.xml                  | 644        | Configuration, not executable      |

### Windows ACLs

After deployment, `windows/profiles.sls` sets Windows ACLs:

```powershell
icacls "C:\Program Files\PowerShell\7" /grant:r "Users:(OI)(CI)(R)" /grant:r "Administrators:(OI)(CI)(F)"
```

- **Users**: Read access (needed to load profile)
- **Administrators**: Full control (can modify)

## Adding New Configuration

### Add a New Tool to Profile

1. **Create config file** in `provisioning/windows/files/PROFILE.AllUsersCurrentHost/config.d/`

   ```powershell
   # newtool.ps1
   try {
       # Initialization logic here
       logging "newtool initialized" "DEBUG"
   } catch {
       if (Get-Command logging -ErrorAction SilentlyContinue) {
           logging "Failed to initialize newtool: $_" "WARN"
       }
   }
   ```

2. **Update main profile** (`Microsoft.PowerShell_profile.ps1`)
   - Add path variable: `$newtool = "$profileDir\config.d\newtool.ps1"`
   - Add to Script-Loader call in appropriate section

3. **Run fix-permissions**

   ```bash
   ./scripts/fix-permissions.sh
   ```

4. **Deploy with Salt**
   - Profile files automatically deploy via `windows/profiles.sls`
   - No state file changes needed (recursive deployment)

### Add a New Scheduled Task

1. **Create task XML** in `provisioning/windows/tasks/{category}/`
   - Based on Windows Task Scheduler XML format
   - See existing tasks for examples

2. **Create Salt state** in `srv/salt/windows/tasks/{category}.sls`
   - Deploy XML via `file.managed`
   - Register task via `cmd.run` with `schtasks.exe`

3. **Include in orchestration** in `srv/salt/windows/init.sls`

## Troubleshooting

### Profile Load Issues

If PowerShell fails to load profile:

1. **Check Windows ACLs**:

   ```powershell
   icacls "C:\Program Files\PowerShell\7"
   ```

2. **Test individual config files**:

   ```powershell
   . "C:\Program Files\PowerShell\7\config.d\npm.ps1"
   ```

3. **Check for syntax errors**:
   ```powershell
   Test-Path "C:\Program Files\PowerShell\7\profile.ps1"
   Get-Content "C:\Program Files\PowerShell\7\profile.ps1" | powershell -Command { . $input }
   ```

### Module Import Failures

If modules fail to import:

- Check `logging "Failed to import $module"` messages
- Verify module is installed: `Get-Module -ListAvailable`
- Try manual import: `Import-Module Terminal-Icons`

### Scheduled Task Issues

If tasks don't run:

1. **Verify task registration**:

   ```powershell
   Get-ScheduledTask -TaskPath "\cozy\" -TaskName "*"
   ```

2. **Check task logs**:

   ```powershell
   Get-WinEvent -LogName "Microsoft-Windows-TaskScheduler/Operational"
   ```

3. **Re-register task**:
   ```powershell
   schtasks /create /tn "cozy\task-name" /xml "C:\path\to\task.xml" /f
   ```

## Related Documentation

- **Deployment states**: `srv/salt/windows/`
- **Script organization**: `scripts/README.md`
- **Windows enrollment**: `docs/WINDOWS-ENROLLMENT.md`
- **PowerShell profile source**: Source files in this directory
