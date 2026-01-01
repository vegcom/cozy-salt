# cozy-salt TODO - Active Work

**Status:** Active Development | **Last Updated:** 2025-12-31

## Active Work

### Kali Host (guava) Issues

- [ ] **Docker repo 404 on Kali** - `download.docker.com/linux/kali` doesn't exist
  - Salt is creating both Kali AND Debian repos, Kali one 404s
  - Also has errant `testing` component in Debian bookworm repo
  - Need to clean up `/etc/apt/sources.list.d/docker*.list` on host
  - Fix: Ensure Kali detection uses Ubuntu `noble` repo only

- [x] **cozyusers group not created before user states**
  - Fixed: Added explicit `order:` parameters (groups: 1-2, users: 10)

- [x] **Homebrew installation chain fails**
  - Fixed: Added order: 20 and explicit require for cozyusers_group

### Windows Issues

- [x] **Windows user creation** - PowerShell group workaround tested, working
- [x] **nvm PATH issue** - Fixed to use full path `C:\opt\nvm\nvm.exe`
- [x] **OpenSSH default shell** - Added registry key for pwsh.exe
- [x] **miniforge pip_base packages** - Added uv/uvx via common.miniforge
- [x] **NVM_SYMLINK env var** - Added to registry + inline env for nvm use/npm commands

---

## Future Improvements

### Makefile Validation Targets

- [x] **Add `make validate-states` target** (implemented)
  - `validate-states`: Linux states via containerized salt-call
  - `validate-states-windows`: Windows states (run on Windows host)
  - Catches YAML/Jinja syntax errors before deploy

### User Roles

- [ ] **Add role-based group assignment for users**
  - Roles: `admin`, `devops`, `user`
  - admin: full access (docker, kvm, libvirt, sudo)
  - devops: TBD (subset of admin)
  - user: basic access (cozyusers only)
  - Define in pillar, resolve to groups in state

### Default cmd.run Environment Variables

- [ ] **Create Jinja macro for Windows cmd.run with standard env**
  - Wrap cmd.run with consistent NVM_HOME, NVM_SYMLINK, CONDA_HOME, etc.
  - Single source of truth for Windows tool paths
  - Example: `{% from "macros/windows.sls" import win_cmd %}`
  - Options:
    1. Jinja macro in `srv/salt/macros/windows.sls`
    2. Custom state module extending `cmd.run`
    3. Pillar-based defaults with `| default(pillar.get('win_env'))` pattern
  - Benefits: DRY, consistent env across all states, easier debugging

---

## Completed Work Summary (2025-12-31)

All items from consolidation phase have been completed and merged to main:
- P0+P1 Consolidation (150+ lines bloat reduction)
- P2 Linux & Windows package organization
- Critical security fixes (auto_accept removal, pre-shared keys)
- Infrastructure hardening (SSH, healthchecks, base images)
- Code consolidation (Dockerfiles, YAML anchors, macros, common modules)
- Architecture documentation (10 ADRs)
- Pre-commit hooks for automated validation

See git history for implementation details.
