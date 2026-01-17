# cozy-salt TODO - Active Work

**Status:** Active Development | **Last Updated:** 2026-01-16

---

## ✅ COMPLETED (This Session)

- ✅ Extract Docker installation to `srv/salt/common/docker.sls`
- ✅ Move GPU detection to `srv/salt/common/gpu.sls`
- ✅ Fix PowerShell module duplication (merged to single `powershell_gallery` list)
- ✅ Clean up git_env.sls (removed dead Windows code)
- ✅ Refactor linux/install.sls capability loops (metadata-driven, 60+ lines eliminated)
- ✅ Delete unused pillar fields (cozy:base_path, shell:*, packages:*, docker:*, tasks:*, etc.)
- ✅ Fix SSH config (removed broken dual-port binding, added pillar gate)
- ✅ Design package conflict resolution strategy (multi-distro support)
- ✅ Create distro-specific install structure:
  - `srv/salt/linux/install.sls` → dispatcher
  - `srv/salt/linux/dist/debian.sls` → Debian/Ubuntu packages
  - `srv/salt/linux/dist/rhel.sls` → RHEL/CentOS/Fedora packages
  - `srv/salt/linux/dist/archlinux.sls` → Arch/Manjaro packages
- ✅ Create Arch pillar skeleton (`srv/pillar/arch/init.sls`)
- ✅ Create Steam Deck hardware config structure:
  - `srv/pillar/class/galileo.sls` → Hardware class defaults
  - `srv/pillar/host/guava.sls` → Host-specific overrides
  - `srv/salt/linux/config-steamdeck.sls` → Hardware detection & config application
  - Updated `srv/pillar/top.sls` → Class & host pillar routing
  - Updated `srv/salt/linux/config.sls` → Include config-steamdeck

---

## P1: Active - Steam Deck / ArchLinux Bootstrap

### YAY Installation & Wrapper Setup

**Context:** YAY is NOT in official repos, must bootstrap from AUR first

**Bootstrap sequence (MANUAL - happens before Salt deployment):**
```bash
sudo pacman -S --needed git base-devel
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin && makepkg -si
```

**Task:**
- [ ] After bootstrap, deploy yay_clean wrapper to ~/.bashrc
  - The wrapper strips NVM/Conda/Cargo/JAVA_HOME/Qt/compiler vars so AUR builds don't pollute system
  - Prevents /opt tools from leaking into system package builds
  - User role: vegcom (or deck on Steam Deck)
  - Deployment: Via minion post-bootstrap (shell state or manual)
  - Effort: 30 minutes

### Minimal Arch Packages Configuration

**Task:**
- [ ] Update `provisioning/packages.sls` arch section with CORE TOOLING ONLY
  - Already has: core_utils, build_tools, modern_cli, shell_enhancements, networking, compression, vcs_extras, security, acl, kvm
  - ADD: interpreters (python, perl, lua), shell_history (atuin), modern_cli_extras (eza, zoxide, delta, etc.)
  - ADD with pillar gates: fonts, theming
  - Effort: 1 hour
  - Files: `provisioning/packages.sls` (arch section)

### Atuin Shell History Integration

**Context:** Currently broken ("not working at all")

**Task:**
- [ ] Debug atuin on maple-trees using checklist
  - Check: is atuin installed? in PATH? initialized in .bashrc? bash-preexec present?
  - Fix: Either repair integration or add to config-steamdeck.sls for Salt deployment
  - Effort: 1 hour (investigation)

### Steam Deck Pillar-Based Configuration

**Status:** COMPLETE
- ✅ `class/galileo.sls` - Hardware defaults with repo/display/input artifacts (all disabled)
- ✅ `host/guava.sls` - Host overrides (can enable features in pillar)
- ✅ `config-steamdeck.sls` - State that detects hardware + applies config from pillar
- ✅ `top.sls` - Class/host routing

**What it handles:**
- Display rotation (xrandr) - gate via `display:rotation:enabled`
- Touch mapping (xinput) - gate via `display:touch_mapping:enabled`
- Steam input config - gate via `steam_input:hardware_config:enabled`
- Bluetooth service - gate via `bluetooth:enabled`
- Pacman repos - artifact/commented in pillar (disabled by default)

---

## P2: Medium Priority

### Package Conflict Metadata

**Files:** `provisioning/packages.sls`

**Task:**
- [ ] Add `package_metadata` section (distro_aliases, conflicts, optional, required, provides)
  - Status: Designed, needs implementation
  - Effort: 1 hour
  - Will enable distro aliases (kali→ubuntu, rocky→rhel, manjaro→arch)

### Architecture Package Fixes

**File:** `provisioning/packages.sls` (arch section)

**Task:**
- [ ] Verify arch package names are correct
  - Status: Fixed by egirl-ops (vim, fd, github-cli, openssh, libvirt, etc.)
  - Effort: None (already done in design)

---

## P3: Low Priority - Windows Cleanup

### Hardcoded Windows Paths Parameterization

- [ ] Parameterize Windows paths via pillar
  - `C:\Program Files\PowerShell\7\`
  - `C:\ProgramData\ssh\sshd_config.d\`
  - Effort: 1.5 hours

### Git Environment Variables - Windows

- [ ] Fix or document Windows implementation
  - Effort: 1 hour

### Windows Scheduled Tasks Flexibility

- [ ] Move to pillar-driven configuration
  - Effort: 30 minutes

### Steam Deck SDDM Theme

- [ ] Install and configure SDDM Astronaut theme
  - https://github.com/Keyitdev/sddm-astronaut-theme
  - Instead of running their script, use Salt file.managed to deploy theme files
  - Add pillar gate: `steamdeck:sddm:theme` (default: sugar-dark, option: astronaut)
  - Effort: 1-2 hours

---

## Future / Backlog

### Immutable Linux Support (Bazzite/SteamOS)

- Support read-only filesystems via Flatpak, distrobox, user-space installs

### User Roles & Group Assignment

- Add role-based access control (admin, devops, user)

### DNS Configuration with Tailscale

- Append nameservers when Tailscale is present

### Windows Test Output Collection

- Add Windows test output path similar to Linux

---

## Notes

- **Steam Deck hostname:** guava (minion ID for pillar routing)
- **Steam Deck system:** Valve Galileo, Serial FYZZ34613B04
- **Steam Deck user:** vegcom (username), /home/vegcom
- **YAY requirement:** Bootstrap manually before Salt deployment
- **Pillar structure:**
  - common/ - all systems
  - linux/ - Linux platform-specific
  - windows/ - Windows platform-specific
  - arch/ - Arch Linux distro
  - class/galileo.sls - Hardware class (Steam Deck)
  - host/guava.sls - Host-specific overrides
- **Rule 3:** Always grep before moving files
- **Recent:** Distro split, package metadata design, Steam Deck config structure complete
