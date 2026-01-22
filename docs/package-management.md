# Package Management in cozy-salt

Complete guide to package management across Linux, Windows, and language-specific packages.

## Overview

Package management in cozy-salt follows **Rule 1**: All packages live in `provisioning/packages.sls`, never hardcoded in state files.

**Location**: `provisioning/packages.sls`
**File Size**: ~664 lines with comprehensive documentation
**Architecture**: Centralized definition, distributed via Salt state imports

## Structure

### 1. Distro Aliases (17 mappings)

Maps OS variant names (reported by Salt grains) to base distribution families:

- **Ubuntu-based**: ubuntu, kali, linuxmint, pop, elementary, zorin, ubuntu-wsl
- **RHEL-based**: rhel, rocky, alma, centos, fedora, oracle, scientific
- **Arch-based**: arch, manjaro, endeavouros, garuda, artix, arcolinux

Example:

```yaml
distro_aliases:
  kali: ubuntu # Kali uses Ubuntu repo structure
  manjaro: arch # Manjaro uses Arch package manager
```

### 2. Package Metadata

Cross-cutting package concerns not tied to a single distro.

#### Conflicts

Packages that conflict with each other (user must choose one):

- MySQL variants: mysql, mariadb, percona-server
- Java versions: openjdk-17-jdk, java-21-openjdk-devel, etc.
- Netcat variants: netcat-openbsd, nmap-ncat, openbsd-netcat
- Container runtimes: docker-ce, podman, containerd
- Firewalls: ufw, firewalld, iptables-persistent

#### Optional Packages

Packages users might want to install:

- Modern CLI tools: bat, fd, ripgrep, fzf, duf, ncdu, delta, zoxide
- Dev extras: gh, git-lfs, tig, lazygit
- Shell extras: zsh-autosuggestions, zsh-syntax-highlighting, starship

#### Required Packages

Core packages that should always be present:

- **Core**: curl, git, openssh, ca-certificates
- **Build**: gcc, make
- **Network**: ping, traceroute, dig, avahi

#### Exclude

Packages not available on specific distros:

- **Arch**: cpu-checker, build-essential (use base-devel), openssh-client (use openssh), vim-enhanced, fd-find, gnupg2
- **RHEL**: duf, ncdu (not in base repos, need EPEL)
- **Debian**: github-cli (use gh instead)

#### Provides

Cross-distro package name mappings (same functionality, different package names):

```yaml
provides:
  vim:
    ubuntu: vim
    debian: vim
    rhel: vim-enhanced # RHEL names it vim-enhanced
    arch: vim
  build_essentials:
    ubuntu: build-essential
    debian: build-essential
    rhel: [gcc, gcc-c++, make, autoconf, automake] # List on RHEL
    arch: base-devel # Group on Arch, not individual packages
  github_cli:
    ubuntu: gh
    debian: gh
    rhel: gh
    arch: github-cli # Different name on Arch!
```

### 3. Linux Distributions (4 major families)

#### Ubuntu

- Debian-based, uses `apt`
- Modern repos with latest versions
- Includes: duf, ncdu (available in repos)
- Includes modern CLI tools (bat, fd-find, ripgrep)

#### Debian

- Stable, Debian-based, uses `apt`
- Nearly identical to Ubuntu (tested and equivalent)
- Conservative versioning
- Same package availability as Ubuntu

#### RHEL (Rocky, Alma, CentOS, Fedora)

- Uses `dnf`/`yum`
- More conservative repos
- Excludes: duf, ncdu (need EPEL repo)
- Uses vim-enhanced instead of vim
- Uses \*-clients variant names (openssh-clients, bind-utils)

#### Arch Linux

- Most comprehensive package set
- Uses `pacman` + `yay` (AUR helper)
- Bleeding edge versions
- **Extra groups** (4 Arch-exclusive capabilities):
  - `interpreters`: lua, perl, python, python-pip
  - `fonts`: Noto, Fira Code, Hack, JetBrains Mono
  - `modern_cli_extras`: bottom, delta, eza, hyperfine, procs, tealdeer, tokei, zoxide
  - `theming`: arc-gtk-theme, kvantum, papirus-icon-theme
- Requires special handling:
  - `base-devel` is a package GROUP, not individual packages
  - `openssh` is unified (no separate client/server)
  - Package names differ: `github-cli` instead of `gh`, `fd` instead of `fd-find`

### 4. Windows Packages

#### PowerShell Gallery

System-level PowerShell modules:

- PSReadLine: Command-line editing and history
- PowerShellGet: Module management
- Microsoft.WinGet.Client: WinGet interface
- PSFzf: Fuzzy finder integration
- PSWindowsUpdate: Windows Update management
- Terminal-Icons: File icons in terminal

#### Chocolatey

Universal Windows package manager:

- Extensions: chocolatey-core, chocolatey-compatibility
- Development: vim, make, docker-cli, docker-compose
- Utilities: Cygwin, colortool
- Fonts: nerd-fonts-FiraCode, nerd-fonts-Hack
- Games: cheatengine

#### Winget

Microsoft's modern package manager with 3 sections:

**winget_runtimes**: System dependencies

- UI Libraries: Microsoft.UI.Xaml 2.7, 2.8
- Visual C++ Runtimes: 2008-2015+ x64/x86
- SDKs: Windows ADK, Windows SDK
- .NET: AspNetCore 9, DesktopRuntime 8/9/10

**winget_system**: Development and utilities

- Sync/Backup: FreeFileSync, Syncthing
- File Management: 7zip, WinSCP
- Terminal: Windows Terminal, ConEmu, PowerShell
- Development: IntelliJ, Visual Studio, VS Code
- Version Control: Git, GitHub Desktop

**winget_userland**: User applications

- Media: ImageMagick, FFmpeg, HandBrake, OBS
- Games: GOG, Epic Games, Steam
- Communication: Discord, Telegram, Thunderbird
- Browser: Firefox, Chrome, Thorium
- Utilities: qBittorrent, VoiceMeeter, ImHex

### 5. Language Managers

#### pip_base (Python)

Global Python packages:

- pip: Ensure latest version
- setuptools: Python build tool
- wheel: Wheel package format
- pipx: Python application manager

#### npm_global (Node.js)

Global Node.js packages:

- Build tools: webpack, pnpm, bun, tsx
- CLI tools: @angular/cli, @nestjs/cli, @vue/cli, create-react-app
- Development: nodemon, pm2
- Infrastructure: serverless, aws-cdk

## Capability Groups (All Distros)

Package groups organized by functionality. States in `srv/salt/linux/install.sls` install these via capability metadata from `srv/pillar/linux/init.sls`.

| Group                | Purpose             | All Distros? | Notes                                                         |
| -------------------- | ------------------- | ------------ | ------------------------------------------------------------- |
| `core_utils`         | Essential utilities | ✓            | curl, git, jq, rsync, tree, vim, wget                         |
| `shell_enhancements` | Shell tools         | ✓            | tmux, zsh, bash-completion                                    |
| `monitoring`         | System monitoring   | ✓            | htop, lsof, strace, sysstat (minus duf/ncdu on RHEL)          |
| `compression`        | Archive tools       | ✓            | zip, bzip2, p7zip, xz                                         |
| `vcs_extras`         | Version control     | ✓            | gh, git-lfs, tig                                              |
| `modern_cli`         | CLI replacements    | ✓            | bat, fd, fzf, ripgrep                                         |
| `security`           | Security tools      | ✓            | ca-certificates, gnupg(2)                                     |
| `acl`                | ACL utilities       | ✓            | acl package                                                   |
| `build_tools`        | Build essentials    | ✓            | gcc, make, cmake, autoconf                                    |
| `networking`         | Network tools       | ✓            | openssh, bind, netcat, nmap, tcpdump, traceroute              |
| `kvm`                | Virtualization      | ✓            | libvirt, qemu, virt-install (gated by pillar)                 |
| `shell_history`      | Shell history       | ✓            | atuin                                                         |
| `interpreters`       | Languages           | Arch only    | lua, perl, python, python-pip                                 |
| `modern_cli_extras`  | Advanced CLI        | Arch only    | bottom, delta, eza, hyperfine, procs, tealdeer, tokei, zoxide |
| `fonts`              | Developer fonts     | Arch only    | Noto, Fira Code, Hack, JetBrains Mono                         |
| `theming`            | Themes/Icons        | Arch only    | arc-gtk, kvantum, papirus-icons                               |

## Usage in State Files

All state files import packages using the same pattern:

```sls
{% import_yaml "provisioning/packages.sls" as packages %}

install_core_utils:
  pkg.installed:
    - pkgs: {{ packages[grains['os']]['core_utils'] }}
```

**Files using this pattern**:

- `srv/salt/linux/dist/debian.sls`
- `srv/salt/linux/dist/rhel.sls`
- `srv/salt/linux/dist/archlinux.sls`
- `srv/salt/common/miniforge.sls`
- `srv/salt/common/nvm.sls`
- `srv/salt/windows/install.sls`

## Pillar Integration

Package capabilities are tied to workstation roles via `srv/pillar/linux/init.sls`:

```yaml
role_capabilities:
  workstation-minimal:
    - core_utils
    - shell_enhancements

  workstation-base:
    - core_utils
    - shell_enhancements
    - monitoring
    - compression
    - vcs_extras
    - modern_cli
    - security
    - acl

  workstation-developer:
    - [all of base, plus]
    - build_tools
    - networking
    - kvm

  workstation-full:
    - [all of developer, plus]
    - interpreters
    - shell_history
    - modern_cli_extras
    - fonts
    - theming
```

Capability metadata defines state names and options:

```yaml
capability_meta:
  kvm:
    state_name: kvm_packages
    pillar_gate: host:capabilities:kvm # Only install if enabled
    has_service: libvirtd # Enable this service
    has_user_groups: # Add user to these groups
      - kvm
      - libvirt
```

## Architecture Benefits

1. **Single Source of Truth**: All packages in one file, organized by distro
2. **No Hardcoding**: States never hardcode packages (Rule 1 compliance)
3. **Cross-Distro Consistency**: Ubuntu/Debian identical, RHEL/Arch appropriate differences
4. **Easy Maintenance**: Add a package once, automatically available to all states
5. **Clear Documentation**: Section headers, inline comments, and provides mappings
6. **Flexible Installation**: Capabilities can be enabled/disabled via pillar
7. **Distro Detection**: Automatic mapping of variants (Kali → Ubuntu, Rocky → RHEL, etc.)

## Common Operations

### Add a new package to all distros

1. Add to each distro section in `provisioning/packages.sls`:

   ```yaml
   ubuntu:
     my_capability:
       - new_package
   debian:
     my_capability:
       - new_package
   rhel:
     my_capability:
       - alternative_name # if different
   arch:
     my_capability:
       - arch_name # if different
   ```

2. If different names across distros, add to `provides` section:

   ```yaml
   provides:
     my_package:
       ubuntu: new_package
       rhel: rhel_alternative
       arch: arch_alternative
   ```

### Add a new capability group

1. Define in all 4 distro sections with consistent group name (snake_case)
2. Add entry to `srv/pillar/linux/init.sls` capability_meta:

   ```yaml
   new_capability:
     state_name: new_packages # corresponds to state ID
     pillar_gate: optional.path # if conditional
     has_service: optional_service
     has_user_groups: [optional, groups]
   ```

3. Add to relevant role_capabilities (minimal, base, developer, full)
4. Create state file or add to existing: `state_id: new_packages`

### Handle distro-specific issues

Use `exclude` section for unavailable packages:

```yaml
exclude:
  rhel:
    - package_not_in_repos
```

Use `provides` section for name differences:

```yaml
provides:
  package_name:
    rhel: alternative_name
```

## Consistency Rules

All package definitions must follow:

1. **Snake case**: Use `snake_case` for all group names (core_utils, build_tools, etc.)
2. **All 4 distros**: Define groups in ubuntu, debian, rhel, arch (unless intentionally distro-specific)
3. **No hardcoding**: Never put packages in state files; always import from packages.sls
4. **Document differences**: Use inline comments for distro-specific variations
5. **Group related packages**: Logical grouping by function (monitoring, networking, etc.)

## File Statistics

- **Total lines**: ~664 (with documentation)
- **Distro aliases**: 17 mappings
- **Capability groups**: 16 total (12 shared, 4 Arch-only)
- **Provides mappings**: 10 entries handling cross-distro name differences
- **Exclude entries**: 3 sections covering unavailable packages
- **Total packages**: ~300+ across all distros/managers

## See Also

- [CONTRIBUTING.md](../CONTRIBUTING.md) - Rule 1: Packages in provisioning/packages.sls
- [CLAUDE.md](../CLAUDE.md) - Three rules of cozy-salt
- `srv/salt/linux/install.sls` - How packages are installed
- `srv/pillar/linux/init.sls` - Capability metadata and role definitions
