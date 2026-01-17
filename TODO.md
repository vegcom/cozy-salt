# cozy-salt TODO - Active Work

**Status:** Active Development | **Last Updated:** 2026-01-16

---

## P1: High Priority - Architecture Refactoring

### Docker State Extraction

**Files:** `srv/salt/linux/install.sls` (lines 26-73), `provisioning/packages.sls`

- [ ] Extract Docker installation to separate `srv/salt/common/docker.sls`
  - Current: Messy Kali/WSL detection and repo fixup embedded in install.sls
  - Move: docker_install, docker_repo_cleanup, docker_repo_fix, apt_update_with_override
  - Benefit: Cleaner, reusable across platforms, easier to maintain
  - Effort: 1 hour

### GPU Detection Relocation

**Files:** `srv/salt/linux/install.sls` (lines 212-234)

- [ ] Move GPU detection to `srv/salt/common/gpu.sls`
  - Current: Detects nvidia/amd/other, sets linux_gpu grain, but only run on Linux
  - New: Move to common, add platform detection wrapper
  - Benefit: Can be targeted by Windows states if needed (e.g., nvidia driver detection)
  - Effort: 1 hour

### SSH Port Binding Fix - Implementation Review

**Files:** `srv/salt/_templates/sshd_hardening.conf.jinja` (port configuration)

- [ ] Verify SSH config doesn't bind dual ports (2222 + default)
  - Current: Fixed to use main sshd_config or null then set (not separate file)
  - Validate: `netstat -tlnp | grep sshd` shows only one port listening
  - Test: Run on Debian/Kali/Windows
  - Effort: 30 minutes validation

### Linux Package Name Handling - Distro Divergence Strategy

**Files:** `srv/salt/linux/install.sls`, `provisioning/packages.sls`

- [ ] Design package conflict resolution for multi-distro setups
  - Issue: Package names differ across Debian/RHEL/Arch; some conflict
  - Current: Only ubuntu/rhel mappings
  - Options: 
    - (A) Per-distro lists in packages.sls with `os_family` filter
    - (B) Common base list + per-distro overrides
    - (C) Capability-based install (current) + distro gating per package
  - ArchLinux: Needs separate handling (pacman, no apt/yum)
  - Effort: 2 hours design + implementation

### ArchLinux Support Skeleton

**Target:** Steam Deck native ArchLinux

- [ ] Create `srv/salt/arch/install.sls`
  - Mirror structure: core_utils, build_tools, kvm, etc. via pacman
  - Cross-reference: Map Linux capability sets to Arch package names
  - Add to `srv/salt/top.sls` with Arch detection
  - Add pillar support for ArchLinux in `top.sls`
  - Effort: 3 hours

---

## P2: Medium Priority - Duplicate Code Reduction

### Duplicate Invoke-WebRequest Patterns

**Files:** `windows/nvm.sls`, `windows/wt.sls`, `windows/windhawk.sls`, `windows/miniforge.sls`, `windows/rust.sls`

- [ ] Extract Invoke-WebRequest to reusable macro `win_download()` in `macros/windows.sls`
  - Current: 5 separate states with nearly identical download logic
  - Pattern: `pwsh -NoLogo -NoProfile -Command "Invoke-WebRequest -Uri ... -OutFile ..."`
  - Benefit: Reduces duplication, easier to add hash verification later
  - Effort: 1.5 hours

### Duplicate Winget Installation Patterns

**File:** `windows/install.sls` lines 8-104

- [ ] Create macro for repeated winget install loops
  - Current: Three blocks (winget_runtimes, winget_system, winget_userland) with identical logic
  - Pattern: Parameterize as `win_package(packages, scope, description)`
  - Benefit: Single source of truth for package install logic
  - Effort: 1 hour

### Duplicate File Append Patterns

**Files:** `windows/users.sls`, `windows/miniforge.sls`

- [ ] Create macro for repeated `file.append` + directory creation patterns
  - Current: 3-4 similar SSH key appends
  - Pattern: `file_append_with_directory(path, content, user, group)`
  - Benefit: Reduces bugs, easier to add permission handling
  - Effort: 1 hour

---

## P3: Low Priority - Features & Polish

### Hardcoded Windows Paths Parameterization

**Files:** Multiple Windows states (`config.sls`, `miniforge.sls`, `tasks.sls`)

- [ ] Parameterize hardcoded Windows paths via pillar
  - `C:\Program Files\PowerShell\7\` (PowerShell install location)
  - `C:\ProgramData\ssh\sshd_config.d\` (SSH config location)
  - `C:\Windows\Temp\` (temp directory)
  - Impact: Flexibility for alternate installations
  - Effort: 1.5 hours

### Git Environment Variables - Windows Implementation

**File:** `common/git_env.sls` lines 15-32

- [ ] Fix disabled Windows git env section or document why unsupported
  - Current: Entire Windows section commented out
  - Issue: Users can't export git credentials on Windows
  - Options: Fix implementation or add feature flag
  - Effort: 1 hour

### Windows Scheduled Tasks Flexibility

**File:** `windows/tasks.sls`

- [ ] Move task definitions from hardcoded to pillar-driven
  - Include enable/disable state management
  - Benefit: Better configuration management
  - Effort: 30 minutes

### Windows Environment Refresh

**Integration point:** Windows highstate final step

- [ ] Add Chocolatey `refreshenv` as last Windows state
  - Currently: New PATH/env vars not available until next session
  - Benefit: Immediately available tools after installation
  - Effort: 30 minutes

---

## Future / Backlog

### Windows Test Output Collection

- [ ] Add Windows test output path similar to Linux
  - Create `tests/output/windows/` for state results
  - Parse Windows failures same as Linux logs

### DNS Configuration with Tailscale

- [ ] Append nameservers when Tailscale is present
  - Tailscale overwrites /etc/resolv.conf, keep as primary + fallbacks

### User Pillar Structure Consolidation

- [ ] Consolidate `managed_users` into `users:` declaration
  - Currently redundant structure, can be simplified

### User Roles & Group Assignment

- [ ] Add role-based access control for users
  - Roles: `admin`, `devops`, `user`

### Immutable Linux Support (Bazzite/SteamOS)

- [ ] Support Bazzite and SteamOS read-only filesystems
  - Bazzite: User-space installs, Flatpak, distrobox
  - SteamOS: Test after enabling read-write mode

---

## Notes

- Before moving ANY file: `grep -Hnr "pattern" srv/salt/ srv/pillar/ provisioning/ scripts/ .github/ tests/` (Rule 3)
- Salt runs as uid 999, needs read access to all .sls/.yml files
- Run `./scripts/fix-permissions.sh` if permission issues occur
- Recent changes: Docker/GPU extraction planned, ArchLinux support incoming, Miniforge→uv migration done
