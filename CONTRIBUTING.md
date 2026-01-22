# Contributing

## 3 Rules

1. **Packages go in `provisioning/packages.sls`** - states import, never hardcode
2. **Files live in `provisioning/`** - states orchestrate, files deploy
3. **Grep before moving anything** - silent failures suck

```bash
grep -Hnr "old_path" srv/salt/ srv/pillar/ provisioning/ scripts/ .github/ tests/ *.md Makefile
```

## Testing

```bash
make test              # All (ubuntu + rhel)
make test-ubuntu       # Ubuntu only
make test-rhel         # RHEL only
make test-windows      # Windows (requires KVM)
```

## When It Breaks

| Problem         | Fix                                                             |
| --------------- | --------------------------------------------------------------- |
| State not found | Check `top.sls` matches filename                                |
| File not found  | Check `provisioning/` mounted                                   |
| Jinja undefined | Add `{% import_yaml "provisioning/packages.sls" as packages %}` |
| Minion hanging  | Master needs 15s after restart                                  |
| Permissions     | Run `./scripts/fix-permissions.sh`                              |

## Windows `win_cmd` Macro

For `cmd.run` states needing NVM/Conda paths:

```sls
{%- from "macros/windows.sls" import win_cmd %}

install_node:
  cmd.run:
    - name: {{ win_cmd('nvm install lts') }}
    - shell: pwsh
```

Sets `NVM_HOME`, `NVM_SYMLINK`, `CONDA_HOME` automatically.

## Pillar Configuration Examples

Pillar template files (committed) show structure and defaults. Copy templates to create instance files:

| Template | Purpose | Instance | Notes |
| --- | --- | --- | --- |
| `srv/pillar/host/example.sls` | Per-host config template | `srv/pillar/host/{hostname}.sls` | Loaded if exists, never tracked |
| `srv/pillar/class/example.sls` | Hardware class template | `srv/pillar/class/{classname}.sls` | Reference for structure |
| `srv/pillar/users/demo.sls` | User config template | `srv/pillar/users/{username}.sls` | Local files only, demo.sls tracked |
| `srv/pillar/common/users.sls.example` | User metadata template | `srv/pillar/common/users.sls` | Shows structure (tracked) |
| `srv/pillar/secrets/init.sls.example` | Secrets template | `srv/pillar/secrets/init.sls` | Gitignored, create locally |

**Creating a new host configuration**:
```bash
cp srv/pillar/host/example.sls srv/pillar/host/myhost.sls
# Edit myhost.sls, set any host-specific pillar values
# File is auto-loaded based on minion hostname
```

**Adding a new managed user**:
```bash
cp srv/pillar/users/demo.sls srv/pillar/users/newuser.sls
# Edit newuser.sls:
# - Change "example_user" to "newuser" in pillar
# - Set groups, SSH keys, github config, tokens
# - Add "newuser" to managed_users list in srv/pillar/common/users.sls
# - User config remains local (see .gitignore)
```

**Git credentials and user config**:
- Credentials stored in `.git-credentials`: `https://username:token@github.com`
- User email/name auto-deploy to `.gitconfig.local [user]` section
- Tokens merge: global (common/users.sls) + per-user (users/{username}.sls)
- See `srv/pillar/users/demo.sls` for github config structure

## Documentation

Module documentation lives in `docs/modules/` (not as inline comments in `.sls` files).

Examples:
- [Salt Scheduler](./docs/modules/scheduler.md) - Pillar configuration and usage for `schedule` module
- [State files](./srv/salt/) - Minimal header comment pointing to `docs/modules/`

When adding a new module:
1. Create `docs/modules/<name>.md` with configuration, options, and examples
2. Reference it from the state file: `# See docs/modules/<name>.md for usage`
3. Minimal pillar template with just a reference to the docs

## Git Workflow

1. Branch from main
2. Make changes following the 3 rules
3. Run tests
4. Commit, push, PR

## Submodules

|                                       repo                                        |                        path                         |
| :-------------------------------------------------------------------------------: | :-------------------------------------------------: |
| [vegcom/cozy-salt-enrollment.git](https://github.com/vegcom/cozy-salt-enrollment) |     [scripts/enrollment/](./scripts/enrollment/)    |

## Dynamic Git Deployments

|                                       repo                                        |                        deployment                        |
| :-------------------------------------------------------------------------------: | :-----------------------------------------------------: |
|           [vegcom/cozy-vim.git](https://github.com/vegcom/cozy-vim)               |    `~/.vim` (per-user via git.latest in gitconfig.sls)   |
|          [vegcom/cozy-pwsh.git](https://github.com/vegcom/cozy-pwsh)              | `C:\Program Files\PowerShell\7` (system-wide via windows/profiles.sls) |
