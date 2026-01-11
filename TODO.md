# cozy-salt TODO - Active Work

**Status:** Active Development | **Last Updated:** 2026-01-10

---

## P2: Medium Priority - Organization

### Scripts Reorganization

Current flat structure at `scripts/` root. Proposed:
- [ ] Create `scripts/ci/` - move `fix-permissions.sh`
- [ ] Create `scripts/setup/` - move `generate-windows-keys.*`
- [ ] Update references in Makefile, .github/workflows, CONTRIBUTING.md
- [ ] Grep all paths before moving (Rule 3)

### Version Pillar

- [x] **Move Windhawk version to pillar** ✓ 2026-01-10
  - Added to `srv/pillar/common/versions.sls`
  - State already reads from pillar with fallback default

### Homebrew Admin Hardcoding

- [x] **Parameterize `admin` user in homebrew.sls** ✓ 2026-01-10
  - Uses first user from `managed_users` pillar
  - Fallback to `nobody` if no managed users defined

---

## Future / Backlog

### Windows Test Output

- [ ] **Add Windows test output path** similar to Linux
  - Create `tests/output/windows/` for Windows state results
  - Parse Windows state failures same as Linux
  - Update `tests/fixtures/docker.py` for Windows log collection

### Enrollment & DNS

- [ ] **DNS config: append nameservers when Tailscale present**
  - Tailscale overwrites /etc/resolv.conf with 100.100.100.100
  - Append local (10.0.0.1) + Cloudflare (1.1.1.1, 1.0.0.1) after Tailscale DNS
  - Keep Tailscale as primary, add fallbacks
  - Detect via tailscale0 interface presence
  - Docs: https://tailscale.com/kb/1235/resolv-conf
  - Docs: https://tailscale.com/kb/1081/magicdns

### User Pillar Structure

- [ ] **Consolidate managed_users into users declaration**
  - Currently have separate `managed_users: [admin, vegcom, eve]` list
  - Redundant with keys in `users:` dictionary
  - Options:
    1. Add `managed: true` field to each user in `users:`
    2. Generate managed_users list dynamically from users dict
    3. Remove managed_users entirely, use `users.keys()` everywhere
  - Affects: `srv/salt/linux/dotfiles.sls`, any state referencing `managed_users`

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

- [x] **Create Jinja macro for Windows cmd.run with standard env** ✓ 2026-01-11
  - Created `srv/salt/macros/windows.sls` with `win_cmd` macro (Jinja macro approach selected)
  - Sets NVM_HOME, NVM_SYMLINK, CONDA_HOME from pillar with defaults
  - Refactored 3 Windows states: `windows/nvm.sls` (2 cmd.run), `common/nvm.sls` (1 cmd.run)
  - Syntax validation passes: `make validate-states`
  - Created CONTRIBUTING.md with usage guide and examples
  - Benefits: DRY, single source of truth, consistent env across all states

---

## Notes

- Before moving ANY file: `grep -Hnr "path" srv/salt/ srv/pillar/ provisioning/ scripts/ .github/ tests/`
- Salt runs as uid 999, needs read access to all .sls/.yml
- Run `./scripts/fix-permissions.sh` if permission issues
- NVM default version: Linux uses `lts/*`, Windows/common use `lts` (verify if intentional)
