# CLAUDE.md - cozy-salt AI Guide

SaltStack IaC for Windows/Linux provisioning. Master in Docker. production ready.

## 3 rules. don't break them.

1. **packages go in `provisioning/packages.sls`** - states import, never hardcode
2. **files live in `provisioning/`** - states orchestrate, files deploy
3. **before moving ANYTHING, grep for references** - silent failures suck worse than broken code

## grep before u ship

moving/renaming/deleting? search everywhere first:

```bash
grep -Hnr "old_path" srv/salt/ srv/pillar/ provisioning/ scripts/ .github/ tests/ scripts/ docs/ *.md Makefile TODO.md SECURITY.md README.md
```

check: `file.managed` sources, `cmd.run` paths, `salt://` references, `top.sls` state names.

## when it breaks

- state not found? check `top.sls` and filename match
- file not found? check `provisioning/` is mounted and readable
- Jinja `undefined` on packages? add `{% import_yaml "provisioning/packages.sls" as packages %}` at top of .sls file (rule 1: states import packages, never hardcode)
- minion hanging? master needs 15s after restart
- permissions? run `./scripts/fix-permissions.sh` (automated via pre-commit hook)
- salt runs as uid 999, needs read access to all .sls/.yml files

### Assess for breaks

- Kali: current host (guava) use `salt-call state.highstate test=true`
- Ubuntu: container use `make test-ubuntu` (or `make test-apt` / `make test-linux`)
- RHEL: container use `make test-rhel`
- Windows: container via kvm (`virsh list --all`) `make test-windows`
- All: sequential use `make test` or `make test-all`

see **CONTRIBUTING.md** for details and setup.

## Docker Repository Auto-Detection

The `srv/salt/linux/install.sls` state auto-detects system type and configures the correct Docker repo:

- **Native Debian** → `https://download.docker.com/linux/debian {codename} stable`
- **Ubuntu/WSL/Kali** → `https://download.docker.com/linux/ubuntu noble stable`

WSL systems are detected via `/proc/version` Microsoft check. Ubuntu/WSL always use `noble` (24.04) codename for Docker repo compatibility, regardless of reported system codename.

**Override via pillar** (if needed for specific systems):
```yaml
docker:
  repo_path: ubuntu  # or: debian
  codename: focal    # override default detection
```

## how we actually work here

- **check DeepWiki + Omnisearch FIRST** - before suggesting changes, know what exists
- **Desktop Commander for file edits** - not Edit/Write tools. use `edit_block` or `write_file` through it
- **Desktop Commander for tests** - `start_process`, run `tests/run.sh`, actually verify shit works
- **Memory + Sequential Thinking** - use these often. document decisions, track context, think out loud
- **grep before u move anything** - see rule #3. seriously. do it.
- **Makefile is ur friend** - maintain, review, and leverage for docker/salt operations

## TODO.md Workflow

Never retain completed tasks in TODO.md on main:

1. **In branch**: Update TODO.md to mark tasks as completed (with dates/commit refs)
2. **Before merge**: Ensure all tests pass
3. **After merge to main**: Remove completed task sections from TODO.md entirely
4. **Commit cleanup**: Commit the TODO.md cleanup separately so history is clean

This keeps TODO.md as active work only. Completed tasks are in git history.
