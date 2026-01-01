# cozy-salt TODO - Active Work

**Status:** Active Development | **Last Updated:** 2025-12-31

## Active Work

### Action Items

- [ ] **Create git token for enrollment** - needed for provisioning new systems
- [ ] **DNS config: append nameservers when Tailscale present**
  - Tailscale overwrites /etc/resolv.conf with 100.100.100.100
  - Append local (10.0.0.1) + Cloudflare (1.1.1.1, 1.0.0.1) after Tailscale DNS
  - Keep Tailscale as primary, add fallbacks
  - Detect via tailscale0 interface presence
  - Docs: https://tailscale.com/kb/1235/resolv-conf
  - Docs: https://tailscale.com/kb/1081/magicdns

### Kali Host (guava) Issues

- [x] **Docker repo 404 on Kali** - Fixed: Kali/WSL detection uses Ubuntu `noble` repo

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

### Immutable Linux (Bazzite/SteamOS)

- [ ] **Support Bazzite and SteamOS distros**
  - **Bazzite**: Read-only `/` filesystem - no changes to system paths
    - No current strategy for miniforge, nvm, rust (all install to /opt)
    - Investigate: user-space installs, Flatpak, distrobox/toolbox
  - **SteamOS**: Can set `/` to read-write, needs investigation
    - May work with existing states after `steamos-readonly disable`
  - Detection: Check for `/etc/os-release` with `ID=bazzite` or `ID=steamos`

### Game Streaming (Sunshine/Moonlight)

- [ ] **Add Sunshine/Moonlight packages with device type distinction**
  - Separate desktop (host) vs steamdeck/portable (client) package sets
  - Existing roles: `minimal`, `base`, `dev`, `gaming`, `full`
  - New device types: `desktop` (Sunshine host) vs `portable` (Moonlight client)
  - **Sunshine** (host/streaming server):
    - Windows: `winget://LizardByte.Sunshine`
    - Source: https://github.com/LizardByte/Sunshine
  - **Vibeshine** (Moonlight + optimizations for Steam Deck):
    - Windows MSI: https://github.com/Nonary/vibeshine/releases/download/1.13.0/Vibeshine.msi
    - Source: https://github.com/Nonary/vibeshine
    - Silent install (all users): `msiexec /i Vibeshine.msi /quiet /norestart ALLUSERS=1`
    - Force reinstall/update: `msiexec /i Vibeshine.msi /quiet /norestart ALLUSERS=1 REINSTALLMODE=vomus REINSTALL=ALL`
    - TODO: Check GitHub releases API for new tags, version pin in pillar
    - Releases API: `https://api.github.com/repos/Nonary/vibeshine/releases/latest`

### Windows Environment Refresh

- [ ] **Add refreshenv as final Windows highstate step**
  - Chocolatey's `refreshenv` reloads PATH and env vars in current session
  - Requires: `Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"; refreshenv`
  - Should be last state to run after all installs complete
  - Ensures new tools are immediately available without logout/reboot

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
