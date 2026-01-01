# cozy-salt TODO - Active Work

**Status:** Active Development | **Last Updated:** 2025-12-31

## Active Work

### Kali Host (guava) Issues

- [ ] **Docker repo 404 on Kali** - `download.docker.com/linux/kali` doesn't exist
  - Salt is creating both Kali AND Debian repos, Kali one 404s
  - Also has errant `testing` component in Debian bookworm repo
  - Need to clean up `/etc/apt/sources.list.d/docker*.list` on host
  - Fix: Ensure Kali detection uses Ubuntu `noble` repo only

- [ ] **cozyusers group not created before user states**
  - Group creation succeeds but users fail with "group not present"
  - Likely ordering issue - group.present needs to run before user.present
  - Cascades to homebrew ACL failures

- [ ] **Homebrew installation chain fails**
  - Depends on cozyusers group existing
  - `/home/linuxbrew` directory creation fails → all brew states fail

### Windows Issues

- [x] **Windows user creation** - PowerShell group workaround tested, working
- [x] **nvm PATH issue** - Fixed to use full path `C:\opt\nvm\nvm.exe`
- [x] **OpenSSH default shell** - Added registry key for pwsh.exe
- [x] **miniforge pip_base packages** - Added uv/uvx via common.miniforge
- [ ] **NVM_SYMLINK env var** - Added to registry + inline env for nvm use/npm commands

---

## Future Improvements

### Makefile Validation Targets

- [ ] **Add `make validate-states` target**
  - Run `salt-call --local slsutil.renderer` on all .sls files
  - Catches YAML/Jinja syntax errors before deploy
  - Call from pre-commit hook and GitHub workflows
  - Example: `find srv/salt -name "*.sls" -exec salt-call slsutil.renderer {} \;`
  - Or use containerized salt-call for CI consistency

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

### Pending Commits

- [ ] Commit all session work:
  - pytest migration (done, committed)
  - Windows users enabled + PowerShell group fix
  - nvm full path fix
  - OpenSSH default shell registry
  - pip_base/common.miniforge additions

---

## Completed Work Summary (2025-12-30)

All items from consolidation phase have been completed and merged to main:
- P0+P1 Consolidation (150+ lines bloat reduction)
- P2 Linux & Windows package organization
- Critical security fixes (auto_accept removal, pre-shared keys)
- Infrastructure hardening (SSH, healthchecks, base images)
- Code consolidation (Dockerfiles, YAML anchors, macros, common modules)
- Architecture documentation (10 ADRs)
- Pre-commit hooks for automated validation

See git history for implementation details.
