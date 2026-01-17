# cozy-salt TODO - Active Work

**Status:** Active Development | **Last Updated:** 2026-01-11

---

## P1: High Priority - Code Quality

### Duplicate Invoke-WebRequest Patterns

**Files:** `windows/nvm.sls`, `windows/wt.sls`, `windows/windhawk.sls`, `windows/miniforge.sls`, `windows/rust.sls`

- [ ] Extract Invoke-WebRequest to reusable macro `win_download()` in `macros/windows.sls`
  - Current: 5 separate states with nearly identical download logic
  - Impact: HIGH - Reduces duplication, improves maintainability
  - Effort: 2 hours
  - Pattern: `pwsh -NoLogo -NoProfile -Command "Invoke-WebRequest -Uri ... -OutFile ..."`

### Disabled Miniforge PowerShell Test Condition

**File:** `windows/miniforge.sls` lines 57-58

- [ ] Fix commented FIXME: `-and` operator in PowerShell `Test-Path`
  - Current: File append isn't idempotent (runs every time)
  - Fix: Use `-And` (capitalized) or rewrite test logic
  - Impact: MEDIUM - Idempotency issue
  - Effort: 1 hour

### Disabled Windows Install Unless Conditions

**File:** `windows/install.sls` lines 55-62

- [ ] Implement working `unless` condition for user-scope winget packages
  - Current: Commented out, packages install every run
  - Investigation: Machine scope works, user scope needs different approach
  - Impact: MEDIUM - Non-idempotent package installation
  - Effort: 1 hour

---

## P2: Medium Priority - Architecture

### Hardcoded Windows Paths Inconsistency

**Files:** Multiple Windows states (`config.sls`, `miniforge.sls`, `tasks.sls`)

- [ ] Parameterize hardcoded Windows paths via pillar
  - `C:\Program Files\PowerShell\7\` (PowerShell install location)
  - `C:\ProgramData\ssh\sshd_config.d\` (SSH config location)
  - `C:\Windows\Temp\` (temp directory)
  - Impact: MEDIUM - Increases flexibility for alternate installations
  - Effort: 1.5 hours
  - Related: Already parameterized `C:\opt\nvm`, `C:\opt\miniforge3`

### Duplicate Winget Installation Patterns

**File:** `windows/install.sls` lines 8-104

- [ ] Create macro for repeated winget install loops (winget_runtimes, winget_system, winget_userland)
  - Current: Three nearly identical blocks with identical check logic
  - Pattern: Parameterize as `win_package(packages, scope, description)`
  - Impact: MEDIUM - Reduces code duplication
  - Effort: 1 hour

### Duplicate File Append Patterns

**Files:** `windows/users.sls`, `windows/miniforge.sls`

- [ ] Create macro for repeated `file.append` + directory creation patterns
  - Current: 3-4 similar SSH key appends in users.sls
  - Pattern: `file_append_with_directory(path, content, user, group)`
  - Impact: MEDIUM - Reduces bug surface area
  - Effort: 1.5 hours

### Git Environment Variables - Windows Implementation

**File:** `common/git_env.sls` lines 15-32

- [ ] Fix disabled Windows git env section or document why unsupported
  - Current: Entire Windows section commented out as non-working
  - Issue: Users can't export git credentials on Windows
  - Options: Fix implementation or add `skip_windows_gitenv` flag
  - Impact: MEDIUM - Feature gap for Windows
  - Effort: 1 hour

---

## P3: Low Priority - Features & Polish

### Windows Scheduled Tasks Flexibility

**File:** `windows/tasks.sls`

- [ ] Move task definitions from hardcoded to pillar-driven
  - FIXME comment: "use pillar" for task definitions
  - Include enable/disable state management (currently hardcoded)
  - Impact: LOW - Better configuration management
  - Effort: 30 minutes

### Inconsistent State Dependencies

**Files:** Multiple Windows states

- [ ] Audit and standardize `require:` vs `require_in:` vs `onchanges:`
  - Current: Mixed patterns throughout codebase
  - Standardize on `require:` for clarity and consistency
  - Impact: LOW - Improves readability and maintenance
  - Effort: 2 hours

### Potentially Unused Import

**File:** `common/miniforge.sls` line 5

- [ ] Verify if `{% import_yaml "packages.sls" as packages %}` is necessary
  - Investigation needed: Only uses `pip_base`, check if needed or redundant
  - Impact: LOW - Code clarity
  - Effort: 15 minutes

### Windows Environment Refresh

**Integration point:** Windows highstate final step

- [ ] Add Chocolatey `refreshenv` as last Windows state
  - Currently: New PATH/env vars not available until next session
  - Implementation: Final state runs `refreshenv` to reload environment
  - Benefits: Immediately available tools after installation
  - Effort: 30 minutes

### NVM Version Default Clarification

**Note in codebase:** `TODO.md:122` (now resolved)

- [ ] Document why Linux uses `lts/*` vs Windows/common using `lts`
  - Status: Still unresolved - either intentional or bug
  - Recommendation: Test and document or unify across platforms
  - Effort: 1 hour

---

## Future / Backlog

### Windows Test Output Collection

- [ ] Add Windows test output path similar to Linux
  - Create `tests/output/windows/` for state results
  - Parse Windows failures same as Linux logs
  - Update `tests/fixtures/docker.py` for Windows log collection

### DNS Configuration with Tailscale

- [ ] Append nameservers when Tailscale is present
  - Tailscale overwrites /etc/resolv.conf with 100.100.100.100
  - Keep as primary, append fallbacks (local + Cloudflare)
  - Detect via `tailscale0` interface presence

### User Pillar Structure Consolidation

- [ ] Consolidate `managed_users` into `users:` declaration
  - Currently redundant: separate `managed_users: [...]` list + `users: {...}` dict
  - Options: Add `managed: true` field OR generate list dynamically OR remove entirely

### User Roles & Group Assignment

- [ ] Add role-based access control for users
  - Roles: `admin`, `devops`, `user`
  - Resolve to group assignments in states
  - Define role hierarchy and capabilities in pillar

### Immutable Linux Support (Bazzite/SteamOS)

- [ ] Support Bazzite and SteamOS read-only filesystems
  - Bazzite: Investigate user-space installs, Flatpak, distrobox
  - SteamOS: Test after enabling read-write mode
  - Detection: Check `/etc/os-release` for distro ID

---

## Notes

- Before moving ANY file: `grep -Hnr "pattern" srv/salt/ srv/pillar/ provisioning/ scripts/ .github/ tests/` (Rule 3)
- Salt runs as uid 999, needs read access to all .sls/.yml files
- Run `./scripts/fix-permissions.sh` if permission issues occur
- New macros should follow `macros/windows.sls` pattern (Jinja for consistency)
- Recent documentation: `scripts/README.md` and `provisioning/windows/README.md`


---

include:
  - winget.system
  - winget.user
  - winget.portable


winget-user-msix:
  cmd.run:
    - name: >
        winget install {{ item }} --source winget --accept-package-agreements --accept-source-agreements
    - runas: {{ pillar['user'] }}
    - loop: {{ pillar['winget']['msix'] }}

portable-tools:
  archive.extracted:
    - name: C:\Tools
    - source: https://winget-cache/{{ item }}.zip
    - loop: {{ pillar['winget']['portable'] }}


=== BURN ===
  Microsoft.DotNet.AspNetCore.9
  Microsoft.DotNet.DesktopRuntime.10
  Microsoft.DotNet.DesktopRuntime.8
  Microsoft.DotNet.DesktopRuntime.9
  Microsoft.DotNet.Framework.DeveloperPack.4.6
  Microsoft.DotNet.HostingBundle.8
  Microsoft.DotNet.Runtime.10
  Microsoft.DotNet.Runtime.8
  Microsoft.PowerToys
  Microsoft.VCRedist.2012.x64
  Microsoft.VCRedist.2012.x86
  Microsoft.VCRedist.2013.x64
  Microsoft.VCRedist.2013.x86
  Microsoft.VCRedist.2015+.x64
  Microsoft.VCRedist.2015+.x86

=== EXE ===
  7zip.7zip
  AutoHotkey.AutoHotkey
  Cockos.REAPER
  CodeSector.TeraCopy
  Google.Chrome.EXE
  Microsoft.OneDrive
  Microsoft.OneDrive
  Microsoft.VCRedist.2008.x64
  Microsoft.VCRedist.2008.x86
  Microsoft.VCRedist.2010.x64
  Microsoft.VCRedist.2010.x86
  Microsoft.WindowsADK
  Microsoft.WindowsSDK.10.0.18362
  MSYS2.MSYS2
  namazso.PawnIO
  Nefarius.HidHide
  Nefarius.HidHide
  ViGEm.ViGEmBus

=== INNO ===
  AntibodySoftware.WizTree
  Audacity.Audacity
  Git.Git
  Microsoft.VisualStudioCode
  Microsoft.VisualStudioCode.Insiders
  Playnite.Playnite
  Rem0o.FanControl
  SpecialK.SpecialK
  TechPowerUp.NVCleanstall
  WinSCP.WinSCP

=== MSI ===
  Microsoft.Edge
  Olivia.VIA

=== MSIX ===
  File-New-Project.EarTrumpet
  JanDeDobbeleer.OhMyPosh
  Microsoft.AppInstaller
  Microsoft.AppInstallerFileBuilder
  Microsoft.Teams
  Microsoft.UI.Xaml.2.7
  Microsoft.UI.Xaml.2.8
  Microsoft.WindowsTerminal

=== MSIX (ZIP) ===
  Microsoft.VCLibs.Desktop.14

=== NULLSOFT ===
  BitSum.ParkControl
  BitSum.ProcessLasso
  evsar3.sshfs-win-manager
  HeroicGamesLauncher.HeroicGamesLauncher
  Insecure.Nmap
  KDE.Krita
  Obsidian.Obsidian
  Rainmeter.Rainmeter
  Valve.Steam
  Vencord.Vesktop
  Wagnardsoft.DisplayDriverUninstaller
  WiresharkFoundation.Wireshark

=== NULLSOFT (ZIP) ===
  Guru3D.RTSS

=== PORTABLE ===
  direnv.direnv
  jqlang.jq
  Kubernetes.kubectl
  Microsoft.NuGet
  Rufus.Rufus
  yt-dlp.yt-dlp

=== PORTABLE (ZIP) ===
  DenoLand.Deno
  Gyan.FFmpeg
  Hashicorp.Terraform
  Hashicorp.TerraformLanguageServer
  Helm.Helm
  junegunn.fzf
  Kubecolor.kubecolor
  LibreHardwareMonitor.LibreHardwareMonitor
  Martchus.syncthingtray
  Microsoft.AIShell
  Microsoft.Sysinternals.Autoruns
  Microsoft.Sysinternals.ProcessExplorer
  Microsoft.VisualStudioCode.CLI
  Microsoft.VisualStudioCode.Insiders.CLI
  mtkennerly.ludusavi
  nektos.act
  Rclone.Rclone
  stern.stern
  Ventoy.Ventoy
  waterlan.dos2unix

=== UNKNOWN ===
  rocksdannister.LivelyWallpaper

=== WIX ===
  Apple.Bonjour
  GitHub.cli
  hoppscotch.Hoppscotch
  Inkscape.Inkscape
  Microsoft.PowerShell
  OpenRGB.OpenRGB
  SSHFS-Win.SSHFS-Win
  Starship.Starship
  WinFsp.WinFsp