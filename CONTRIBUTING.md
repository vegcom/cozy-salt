# Contributing to cozy-salt

## Development Workflow

Before making changes, follow these essential rules:

### Rule 1: Packages in `provisioning/packages.sls`
All software package definitions go in `provisioning/packages.sls`. States import packages, never hardcode them.

### Rule 2: Files in `provisioning/`
Configuration files, scripts, and data files belong in `provisioning/`. States orchestrate, files deploy.

### Rule 3: Grep Before Moving Anything
Before renaming, moving, or deleting files, search for all references:

```bash
grep -Hnr "old_path" srv/salt/ srv/pillar/ provisioning/ scripts/ .github/ tests/ docs/ *.md Makefile TODO.md SECURITY.md README.md
```

Check for: `file.managed` sources, `cmd.run` paths, `salt://` references, and `top.sls` state names.

---

## Windows Environment Variables in cmd.run States

All Windows `cmd.run` states that depend on custom tool installations (NVM, Conda, Rust, etc.) must use the `win_cmd` macro to ensure consistent environment variables.

### Available Macros

**`win_cmd(command, extra_env=None)`** - Wrap PowerShell commands with standard Windows environment variables

**Default environment variables:**
- `NVM_HOME`: C:\opt\nvm (or from `pillar.install_paths.nvm.windows`)
- `NVM_SYMLINK`: C:\opt\nvm\nodejs (symlink target for active Node.js version)
- `CONDA_HOME`: C:\opt\miniforge3 (or from `pillar.install_paths.miniforge.windows`)

### Usage Examples

#### Basic Usage

```sls
{%- from "macros/windows.sls" import win_cmd %}

install_nvm:
  cmd.run:
    - name: {{ win_cmd('nvm install lts') }}
    - shell: pwsh
    - require:
      - cmd: nvm_setup
```

#### With Extra Environment Variables

```sls
{%- from "macros/windows.sls" import win_cmd %}

build_rust_project:
  cmd.run:
    - name: {{ win_cmd('cargo build --release', {'RUST_BACKTRACE': '1'}) }}
    - shell: pwsh
    - require:
      - cmd: rust_install
```

### What the Macro Does

The `win_cmd` macro sets PowerShell environment variables before executing your command:

```powershell
$env:NVM_HOME = "C:\opt\nvm"; $env:NVM_SYMLINK = "C:\opt\nvm\nodejs"; $env:CONDA_HOME = "C:\opt\miniforge3"; your_command_here
```

This ensures that any subsequent tool invocations can find their home directories, regardless of Windows PATH configuration.

### When to Use win_cmd

**Always use `win_cmd` when:**
- Invoking NVM: `nvm install`, `nvm use`, `nvm list`
- Invoking Conda/Mamba: `conda init`, `conda install`
- Any command that reads `NVM_HOME`, `CONDA_HOME`, or `NVM_SYMLINK`
- Running npm packages installed by NVM

**Do NOT use `win_cmd` for:**
- Simple system commands (where, whoami, Get-ChildItem)
- Commands that don't depend on custom tool paths
- Registry operations (`reg.present`, `reg.absent`)
- File operations (`file.managed`, `file.directory`)

### Common Patterns

#### Conditionally Running Commands by OS

When a state runs on both Windows and Linux, use `win_cmd` only on Windows:

```sls
{%- from "macros/windows.sls" import win_cmd %}

install_global_npm_packages:
  cmd.run:
    {% if grains['os_family'] == 'Windows' %}
    - name: {{ win_cmd('npm install -g ' ~ npm_packages | join(' ')) }}
    - shell: pwsh
    {% else %}
    - name: NPM_CONFIG_PREFIX={{ nvm_path }} npm install -g {{ npm_packages | join(' ') }}
    - shell: /bin/bash
    - env:
      - NVM_DIR: {{ nvm_path }}
    {% endif %}
    - require:
      - cmd: nvm_setup
```

---

## Testing

### Syntax Validation

Before committing, validate syntax:

```bash
make validate-states          # Validate Linux states
make validate-states-windows  # Validate Windows states (requires Windows)
```

### Running Tests

```bash
make test                  # Run all tests
make test-ubuntu           # Ubuntu/apt only
make test-rhel             # RHEL/dnf only
make test-windows          # Windows only (requires KVM setup)
make test-quick            # Quick test without Docker rebuild
```

### Makefile Targets

Run `make help` or `make salt-help` to see available commands.

---

## File Permissions

Salt runs as UID 999 and needs read access to all `.sls` and `.yml` files. If you encounter permission errors:

```bash
./scripts/fix-permissions.sh
```

This is also run automatically via pre-commit hooks.

---

## Git Workflow

1. Create a feature branch: `git checkout -b feature/my-feature`
2. Make changes following the 3 rules above
3. Validate syntax and run tests
4. Update TODO.md if completing tracked tasks
5. Commit with clear messages
6. Push and create a pull request

Before merging to main:
- All tests must pass
- TODO.md must be cleaned (remove completed task sections)
- Commit cleanup separately to keep history clean

---

## Common Issues

| Problem | Solution |
|---------|----------|
| State not found | Check `top.sls` - state name must match filename |
| File not found | Check `provisioning/` is mounted and readable |
| Jinja undefined on packages | Add `{% import_yaml "provisioning/packages.sls" as packages %}` at top of `.sls` |
| Minion hanging | Salt master needs 15s after restart |
| Permission errors | Run `./scripts/fix-permissions.sh` |

---

## Further Reading

- docs/default-cmd-env-variables.md - Design details for Windows environment variables
- tests/ - Test fixtures and integration test structure
- provisioning/ - File deployments and package definitions
