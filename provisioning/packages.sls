#!jinja|yaml
# Package Definitions for cozy-salt
# See docs/package-management.md for usage and architecture
#
# This file defines all packages for Linux (Debian, RHEL, Arch), Windows (choco, winget),
# and language managers (pip, npm). Used by:
#   - srv/salt/linux/dist/*.sls for Linux package installation
#   - srv/salt/windows/install.sls for Windows package installation
#   - srv/salt/common/*.sls for cross-platform language package management
#
# Structure:
#   - distro_aliases: Maps OS variants to base distribution names
#   - package_metadata: Conflicts, provides, optional/required packages
#   - ubuntu/debian/rhel/arch: Distribution-specific package groups
#   - powershell_gallery/choco/winget_*: Windows package managers
#   - pip_base/npm_global: Language-specific packages
#
# Capability groups (all 4 Linux distros should define):
#   - core_utils: Essential utilities (curl, git, jq, rsync, tree, vim, etc.)
#   - shell_enhancements: Shell tools (tmux, zsh, bash-completion, etc.)
#   - monitoring: System monitoring (htop, lsof, strace, sysstat, etc.)
#   - compression: Archive tools (zip, bzip2, p7zip, xz)
#   - vcs_extras: Version control extras (gh, git-lfs, tig)
#   - modern_cli: Modern CLI replacements (bat, fd, fzf, ripgrep)
#   - security: Security tools (ca-certificates, gnupg)
#   - acl: ACL utilities
#   - build_tools: Build essentials (gcc, make, cmake, etc.)
#   - networking: Network tools (bind, iputils, netcat, openssh, tcpdump, etc.)
#   - kvm: KVM/libvirt virtualization
#   - shell_history: Shell history tools (atuin)
#   - modern_cli_extras: Arch-only advanced CLI tools
#   - interpreters: Arch-only language interpreters (python, perl, lua)
#   - fonts: Arch-only developer fonts
#   - theming: Arch-only theming (GTK, Qt, icons)

# ============================================================================
# DISTRO ALIAS MAPPING
# Maps OS variants (reported by Salt grains) to base distribution names
# ============================================================================
distro_aliases:
  ubuntu: ubuntu
  ubuntu-wsl: ubuntu WSL Ubuntu uses Ubuntu repos
  wsl: ubuntu WSL default uses Ubuntu repos
  kali: ubuntu Kali is Debian-based, uses Ubuntu approach
  linuxmint: ubuntu Linux Mint is Ubuntu-based
  pop: ubuntu Pop!_OS is Ubuntu-based
  elementary: ubuntu Elementary is Ubuntu-based
  zorin: ubuntu Zorin is Ubuntu-based
  rocky: rhel Rocky Linux is RHEL-compatible
  alma: rhel AlmaLinux is RHEL-compatible
  almalinux: rhel AlmaLinux explicit name
  centos: rhel CentOS 8+ are RHEL-like
  fedora: rhel Fedora uses dnf/yum
  oracle: rhel Oracle Linux is RHEL-compatible
  scientific: rhel Scientific Linux is RHEL-compatible
  manjaro: arch Manjaro is Arch-based
  endeavouros: arch EndeavourOS is Arch-based
  garuda: arch Garuda is Arch-based
  artix: arch Artix is Arch-based
  arcolinux: arch ArcoLinux is Arch-based

# ============================================================================
# PACKAGE METADATA
# Cross-cutting concerns: conflicts, optional/required packages, distro aliases
# ============================================================================
package_metadata:
  # Packages that conflict (user must choose one)
  conflicts:
    database_mysql:
      - mysql
      - mariadb
      - percona-server
    java_17_jdk:
      - openjdk-17-jdk Debian/Ubuntu
      - java-17-openjdk-devel RHEL
      - jdk17-openjdk Arch
    java_21_jdk:
      - openjdk-21-jdk
      - java-21-openjdk-devel
      - jdk21-openjdk
    netcat_variants:
      - netcat-openbsd Ubuntu/Debian preferred
      - nmap-ncat RHEL (comes with nmap)
      - openbsd-netcat Arch preferred
      - gnu-netcat Legacy
    mta:
      - postfix
      - sendmail
      - exim4
    container_runtime:
      - docker-ce
      - podman
      - containerd
    firewall:
      - ufw
      - firewalld
      - iptables-persistent

  # Optional packages for consideration
  optional:
    modern_cli_tools:
      - bat cat replacement
      - fd find replacement (fd-find on Debian)
      - ripgrep grep replacement
      - fzf fuzzy finder
      - duf df replacement
      - ncdu du replacement
      - eza ls replacement (formerly exa)
      - delta diff replacement
      - zoxide cd replacement
    dev_extras:
      - gh GitHub CLI
      - git-lfs Large file support
      - tig Git TUI
      - lazygit Git TUI alternative
    shell_extras:
      - zsh-autosuggestions
      - zsh-syntax-highlighting
      - starship Cross-shell prompt

  # Core packages that should always be present
  required:
    core:
      - curl
      - git
      - openssh Or openssh-client on Debian
      - ca-certificates
    build:
      - gcc
      - make
    network:
      - ping Or iputils-ping
      - traceroute
      - dig Or bind-utils/dnsutils
      - avahi

  # Packages to exclude on specific distros (not available or use alternative)
  exclude:
    arch:
      - cpu-checker Doesn't exist on Arch
      - build-essential Use base-devel group instead
      - openssh-client Use unified openssh
      - openssh-server Use unified openssh
      - vim-enhanced Just use vim
      - fd-find Just use fd
      - gnupg2 Just use gnupg
    rhel:
      - duf Not in base RHEL repos (needs EPEL)
      - ncdu Not in base RHEL repos (needs EPEL)
    debian:
      - github-cli Use gh (from GitHub's repo)

  # Package name mappings across distros (provide alternatives)
  provides:
    vim:
      ubuntu: vim
      debian: vim
      rhel: vim-enhanced
      arch: vim
    avahi:
      ubuntu: avahi-daemon
      debian: avahi-daemon
      rhel: avahi
      arch: avahi
    netcat:
      ubuntu: netcat-openbsd
      debian: netcat-openbsd
      rhel: nmap-ncat
      arch: openbsd-netcat
    build_essentials:
      ubuntu: build-essential
      debian: build-essential
      rhel: ['gcc', 'gcc-c++', 'make', 'autoconf', 'automake']
      arch: base-devel This is a GROUP on Arch
    ssh_client:
      ubuntu: openssh-client
      debian: openssh-client
      rhel: openssh-clients
      arch: openssh Unified package
    ssh_server:
      ubuntu: openssh-server
      debian: openssh-server
      rhel: openssh-server
      arch: openssh Unified package
    dns_utils:
      ubuntu: bind9-dnsutils
      debian: bind9-dnsutils
      rhel: bind-utils
      arch: bind
    compression_7z:
      ubuntu: 7zip
      debian: 7zip
      rhel: p7zip
      arch: p7zip Or 7zip (both work)
    github_cli:
      ubuntu: gh
      debian: gh
      rhel: gh
      arch: github-cli Different name on Arch!
    shellcheck:
      ubuntu: shellcheck
      debian: shellcheck
      rhel: ShellCheck
      arch: shellcheck

# ============================================================================
# UBUNTU PACKAGES
# Debian-based, uses apt, includes modern CLI tools
# ============================================================================
ubuntu:
  core_utils:
    - curl
    - git
    - jq
    - rsync
    - tree
    - unzip
    - vim
    - wget
  monitoring:
    - duf
    - htop
    - lsof
    - ltrace
    - ncdu
    - strace
    - sysstat
  shell_enhancements:
    - bash-completion
    - screen
    - tmux
    - shellcheck
  build_tools:
    - autoconf
    - automake
    - build-essential
    - cmake
    - pkg-config
  networking:
    - bind9-dnsutils
    - iputils-ping
    - net-tools
    - netcat-openbsd
    - nmap
    - openssh-client
    - openssh-server
    - socat
    - tcpdump
    - traceroute
    - avahi
  compression:
    - 7zip
    - bzip2
    - xz-utils
    - zip
  vcs_extras:
    - gh
    - git-lfs
    - tig
  modern_cli:
    - bat
    - fd-find
    - fzf
    - ripgrep
  security:
    - ca-certificates
  acl:
    - acl
  kvm:
    - cpu-checker
    - libvirt-clients
    - libvirt-daemon-system
    - qemu-system-x86
    - qemu-utils
    - virtinst

# ============================================================================
# DEBIAN PACKAGES
# Stable, Debian-based, uses apt. Identical to Ubuntu in most cases.
# ============================================================================
debian:
  core_utils:
    - curl
    - git
    - jq
    - rsync
    - tree
    - unzip
    - vim
    - wget
  monitoring:
    - duf
    - htop
    - lsof
    - ltrace
    - ncdu
    - strace
    - sysstat
  shell_enhancements:
    - bash-completion
    - screen
    - tmux
    - shellcheck
  build_tools:
    - autoconf
    - automake
    - build-essential
    - cmake
    - pkg-config
  networking:
    - bind9-dnsutils
    - iputils-ping
    - net-tools
    - netcat-openbsd
    - nmap
    - openssh-client
    - openssh-server
    - socat
    - tcpdump
    - traceroute
    - avahi
  compression:
    - 7zip
    - bzip2
    - xz-utils
    - zip
  vcs_extras:
    - gh
    - git-lfs
    - tig
  modern_cli:
    - bat
    - fd-find
    - fzf
    - ripgrep
  security:
    - ca-certificates
  acl:
    - acl
  kvm:
    - cpu-checker
    - libvirt-clients
    - libvirt-daemon-system
    - qemu-system-x86
    - qemu-utils
    - virtinst


# ============================================================================
# RHEL PACKAGES
# RedHat-based (Rocky, Alma, CentOS, Fedora), uses dnf/yum
# Note: duf and ncdu excluded (not in base RHEL repos, need EPEL)
# ============================================================================
rhel:
  core_utils:
    - curl
    - git
    - jq
    - rsync
    - tree
    - unzip
    - vim-enhanced RHEL provides vim-enhanced, not vim
    - wget
  monitoring:
    - htop
    - lsof
    - ltrace
    - strace
    - sysstat
  shell_enhancements:
    - bash-completion
    - screen
    - tmux
    - shellcheck
  build_tools:
    - autoconf
    - automake
    - cmake
    - gcc
    - gcc-c++
    - make
  networking:
    - bind-utils
    - iputils
    - net-tools
    - nmap
    - nmap-ncat netcat variant for RHEL
    - openssh-clients
    - openssh-server
    - socat
    - tcpdump
    - traceroute
    - avahi
  compression:
    - bzip2
    - p7zip
    - p7zip-plugins
    - xz
    - zip
  vcs_extras:
    - git-lfs
    - tig
  modern_cli:
    - bat
    - fd-find
    - fzf
    - ripgrep
  security:
    - ca-certificates
    - gnupg2
  acl:
    - acl
  kvm:
    - libvirt
    - libvirt-client
    - libvirt-daemon
    - qemu-img
    - qemu-kvm
    - virt-install

# ============================================================================
# ARCH PACKAGES
# Arch Linux, uses pacman + yay (AUR), most bleeding edge, most packages
# Note: Includes extra groups for interpreters, fonts, theming (Arch-only)
# ============================================================================
arch:
  core_utils:
    - curl
    - git
    - jq
    - rsync
    - tree
    - unzip
    - wget
    - sed Built-in utility on most systems, explicit on Arch
    - glibc
    - glibc-locales
  monitoring:
    - duf
    - htop
    - lsof
    - ltrace
    - ncdu
    - strace
    - sysstat
  shell_enhancements:
    - bash-completion
    - screen
    - tmux
    - zsh
    - zsh-autosuggestions
    - zsh-syntax-highlighting
  build_tools:
    - autoconf
    - automake
    - base-devel Arch package GROUP, not individual packages
    - cmake
  networking:
    - bind
    - iputils
    - net-tools
    - nmap
    - openbsd-netcat Arch preferred netcat variant
    - openssh Unified openssh on Arch (client + server)
    - socat
    - tcpdump
    - traceroute
    - avahi
  compression:
    - bzip2
    - p7zip
    - xz
    - zip
  vcs_extras:
    - github-cli Different name on Arch (not gh)
    - git-lfs
    - tig
  modern_cli:
    - bat
    - fd Arch uses fd (not fd-find)
    - fzf
    - ripgrep
  security:
    - ca-certificates
    - gnupg Uses gnupg (not gnupg2)
  acl:
    - acl
  kvm:
    - dnsmasq
    - edk2-ovmf UEFI firmware for QEMU
    - libvirt
    - qemu-desktop QEMU with UI (Arch package name)
    - virt-install
    - virt-manager
  interpreters: Arch-only (other distros compile from source or use nvm/conda)
    - lua
    - perl
    - python
    - python-pip
  modern_cli_extras: Arch-only advanced CLI tools
    - bottom System monitor (similar to htop but better)
    - delta git diff pager (better diffs)
    - eza ls replacement (replaces exa)
    - hyperfine Benchmarking tool for CLI commands
    - procs ps replacement
    - tealdeer tldr pages alternative (tldr command)
    - tokei Code stats / line counter
    - zoxide cd replacement with frecency
  fonts: Arch-only developer fonts
    - noto-fonts
    - noto-fonts-emoji
    - ttf-fira-code Developer font
    - ttf-hack Developer font
    - ttf-jetbrains-mono Developer font
    - inter-font
  theming: Arch-only theming (GTK, Qt, icons)
    - arc-gtk-theme GTK theme
    - kvantum Qt theme engine
    - papirus-icon-theme Icon theme

# ============================================================================
# WINDOWS PACKAGES
# PowerShell Gallery, Chocolatey, Winget, and Visual C++ runtimes
# ============================================================================
windows:
  powershell_gallery:
    - PSReadLine  # Command-line editing, history, syntax highlighting
    - PowerShellGet  # Module management (v3+)
    - Microsoft.WinGet.Client  # WinGet PowerShell interface
    - Microsoft.WinGet.CommandNotFound  # Command not found suggestions
    - powershell-yaml  # YAML parsing
    - PSFzf  # Fuzzy finder integration
    - PSWindowsUpdate  # Windows Update management
    - Terminal-Icons  # File icons in terminal

  choco:
    - chocolatey-compatibility.extension  # Compatibility layer
    - chocolatey-core.extension  # Core extension
    - chocolatey-font-helpers.extension  # Font installation helpers
    - cheatengine  # Game/memory hacking tool
    - colortool  # Windows console colors
    - Cygwin  # Unix-like environment
    - dive  # Docker image analyzer
    - docker-cli  # Docker command-line interface
    - docker-compose  # Docker compose orchestration
    - make  # GNU make build tool
    - nerd-fonts-FiraCode  # Fira Code with Nerd fonts
    - nerd-fonts-Hack  # Hack font with Nerd fonts
    - vim  # Vi improved text editor

  winget_runtimes:
    ui_libraries:
      - Microsoft.UI.Xaml.2.7
      - Microsoft.UI.Xaml.2.8
      - Microsoft.VCLibs.Desktop.14
    vcredist:
      - Microsoft.VCRedist.2012.x64
      - Microsoft.VCRedist.2012.x86
      - Microsoft.VCRedist.2013.x64
      - Microsoft.VCRedist.2013.x86
      - Microsoft.VCRedist.2015+.x64
      - Microsoft.VCRedist.2015+.x86
      - Microsoft.VCRedist.2008.x64
      - Microsoft.VCRedist.2008.x86
      - Microsoft.VCRedist.2010.x64
      - Microsoft.VCRedist.2010.x86
    sdks:
      - Microsoft.WindowsADK
      - Microsoft.WindowsSDK.10.0.18362
      - Microsoft.NuGet
      - Microsoft.AppInstaller
      - Microsoft.AppInstallerFileBuilder
    dotnet:
      - Microsoft.DotNet.AspNetCore.9
      - Microsoft.DotNet.DesktopRuntime.10
      - Microsoft.DotNet.DesktopRuntime.8
      - Microsoft.DotNet.DesktopRuntime.9
      - Microsoft.DotNet.Framework.DeveloperPack.4.6
      - Microsoft.DotNet.HostingBundle.8
      - Microsoft.DotNet.Runtime.10
      - Microsoft.DotNet.Runtime.8

  winget_system:
    sync_backup:
      - FreeFileSync
      - Syncthing
    file_management:
      - 7zip
      - WinSCP
    compression:
      - PeaZip
      - Zipier
    terminal:
      - WindowsTerminal
      - ConEmu
    shell:
      - PowerShell
      - Git.Git
      - StardustXR.Starship
    editor:
      - Vim.Vim
      - NeovimProject.Neovim
    development:
      - JetBrains.IntelliJIDEA.Community
      - Microsoft.VisualStudio.BuildTools
      - Microsoft.VisualStudio.Community
      - Microsoft.VisualStudioCode
      - GitHub.GitHubDesktop
      - Gitleaks.Gitleaks
      - Ombrelin.PandocGui

  winget_userland:
    media:
      - ImageMagick.ImageMagick
      - Wwweasel.PicView
      - Gyan.FFmpeg
      - HandBrake.HandBrake
      - ObsProject.OBS.Studio
    games:
      - GOG.GalaxyClient
      - Epic.EpicGamesLauncher
      - Valve.Steam
    communication:
      - Vencord.Vesktop
      - Telegram.TelegramDesktop.Beta
      - Mozilla.Thunderbird
    browser:
      - Mozilla.Firefox
      - Google.Chrome
      - Thorium.Thorium
    utilities:
      - qBittorrent.qBittorrent
      - ntop.ntop
      - VB-Audio.VoiceMeeter
      - WerWolv.ImHex
      - JohnMacFarlane.Pandoc

# ============================================================================
# LANGUAGE-SPECIFIC PACKAGES
# Python, Node.js, and Rust tools
# ============================================================================
pip_base:
  - pip  # Ensure latest pip version
  - setuptools  # Build tool for Python
  - wheel  # Wheel build format
  - pipx  # Python application package manager

npm_global:
  - pnpm  # Fast npm alternative
  - bun  # Fast JavaScript runtime
  - tsx  # TypeScript executor
  - "@angular/cli"  # Angular CLI
  - "@nestjs/cli"  # NestJS CLI
  - "@vue/cli"  # Vue CLI
  - create-react-app  # React create tool
  - webpack  # Bundler
  - nodemon  # Development file watcher
  - pm2  # Process manager
  - serverless  # Serverless Framework
  - cdk  # AWS CDK CLI

brew:
  - atuin
  - weasyprint
  - pandoc
