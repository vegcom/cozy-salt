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

## Git Workflow

1. Branch from main
2. Make changes following the 3 rules
3. Run tests
4. Commit, push, PR

## Submodules

|                                       repo                                        |                     path                     |
| :-------------------------------------------------------------------------------: | :------------------------------------------: |
| [vegcom/cozy-salt-enrollment.git](https://github.com/vegcom/cozy-salt-enrollment) | [scripts/enrollment/](./scripts/enrollment/) |
