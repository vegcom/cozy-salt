# =============================================================================
# CAPABILITY-BASED PACKAGE CONFIGURATION
# =============================================================================
# Organized by PURPOSE/ROLE, with per-distro package mapping.
#
# USAGE IN STATES:
#   {% import_yaml 'packages.sls' as packages %}
#   {% set os_name = distro_aliases.get(grains['os']|lower, grains['os_family']|lower) %}
#   Then: packages[os_name].core_utils
#
# STRUCTURE:
#   1. distro_aliases    - Maps variant distros to canonical package sets
#   2. package_metadata  - Conflicts, optional, required, provides definitions
#   3. Per-distro lists  - ubuntu, debian, rhel, arch
#   4. Windows/macOS     - Platform-specific (choco, winget, etc.)
#   5. Cross-platform    - pip_base, npm_global
#
# MAINTAINER NOTES:
#   - ubuntu/debian are currently IDENTICAL - see consolidation TODO below
#   - Arch uses unified packages (openssh = client+server, libvirt = all-in-one)
#   - base-devel on Arch is a GROUP, not a package (Salt handles this correctly)
#   - gh (GitHub CLI) is 'github-cli' on Arch, 'gh' elsewhere
# =============================================================================

# =============================================================================
# DISTRO ALIASES
# =============================================================================
# Maps variant/derivative distros to their canonical package set.
# Use in states: packages[distro_aliases.get(os_lower, os_family_lower)]
#
# This allows Kali to use Ubuntu packages, Rocky to use RHEL, etc.
# =============================================================================
distro_aliases:
  # Debian derivatives -> ubuntu packages (use ubuntu repos anyway)
  kali: ubuntu
  linuxmint: ubuntu
  pop: ubuntu
  elementary: ubuntu
  zorin: ubuntu
  # Note: actual Debian uses 'debian' key directly
  
  # RHEL derivatives -> rhel packages
  rocky: rhel
  alma: rhel
  almalinux: rhel
  centos: rhel
  fedora: rhel
  oracle: rhel
  scientific: rhel
  
  # Arch derivatives -> arch packages
  manjaro: arch
  endeavouros: arch
  garuda: arch
  artix: arch
  arcolinux: arch

# =============================================================================
# PACKAGE METADATA
# =============================================================================
# Defines package relationships, conflicts, and classification.
# States can use this for smarter package management.
# =============================================================================
package_metadata:
  # ---------------------------------------------------------------------------
  # CONFLICTS: Mutually exclusive packages (can't install both)
  # ---------------------------------------------------------------------------
  conflicts:
    # Database servers - only one MySQL-compatible server at a time
    database_mysql:
      - mysql
      - mariadb
      - percona-server
    
    # Java JDK versions - typically want only one
    java_17_jdk:
      - openjdk-17-jdk          # Debian/Ubuntu
      - java-17-openjdk-devel   # RHEL
      - jdk17-openjdk           # Arch
    java_21_jdk:
      - openjdk-21-jdk
      - java-21-openjdk-devel
      - jdk21-openjdk
    
    # Netcat variants - functionally similar, pick one
    netcat_variants:
      - netcat-openbsd          # Ubuntu/Debian preferred
      - nmap-ncat               # RHEL (comes with nmap)
      - openbsd-netcat          # Arch preferred
      - gnu-netcat              # Legacy
    
    # Mail Transfer Agents - only one MTA
    mta:
      - postfix
      - sendmail
      - exim4
    
    # Container runtimes
    container_runtime:
      - docker-ce
      - podman
      - containerd
    
    # Firewall managers
    firewall:
      - ufw
      - firewalld
      - iptables-persistent

  # ---------------------------------------------------------------------------
  # OPTIONAL: Nice-to-have packages (may not be in all repos)
  # ---------------------------------------------------------------------------
  optional:
    # Modern CLI replacements - not always in base repos
    modern_cli_tools:
      - bat           # cat replacement
      - fd            # find replacement (fd-find on Debian)
      - ripgrep       # grep replacement
      - fzf           # fuzzy finder
      - duf           # df replacement
      - ncdu          # du replacement
      - eza           # ls replacement (formerly exa)
      - delta         # diff replacement
      - zoxide        # cd replacement
    
    # Development conveniences
    dev_extras:
      - gh            # GitHub CLI
      - git-lfs       # Large file support
      - tig           # Git TUI
      - lazygit       # Git TUI alternative
    
    # Shell enhancements (might need extra repos)
    shell_extras:
      - zsh-autosuggestions
      - zsh-syntax-highlighting
      - starship      # Cross-shell prompt

  # ---------------------------------------------------------------------------
  # REQUIRED: Packages that MUST be present for basic functionality
  # ---------------------------------------------------------------------------
  required:
    # Absolute minimum for any system
    core:
      - curl
      - git
      - openssh       # Or openssh-client on Debian
      - ca-certificates
    
    # Build essentials
    build:
      - gcc
      - make
    
    # Network diagnostics
    network:
      - ping          # Or iputils-ping
      - traceroute
      - dig           # Or bind-utils/dnsutils

  # ---------------------------------------------------------------------------
  # EXCLUDE: Per-distro exclusions (packages that don't exist/work)
  # ---------------------------------------------------------------------------
  exclude:
    arch:
      - cpu-checker           # Doesn't exist on Arch
      - build-essential       # Use base-devel group instead
      - openssh-client        # Use unified openssh
      - openssh-server        # Use unified openssh
      - vim-enhanced          # Just use vim
      - fd-find               # Just use fd
      - gnupg2                # Just use gnupg
    rhel:
      - duf                   # Not in base RHEL repos (needs EPEL)
      - ncdu                  # Not in base RHEL repos (needs EPEL)
    debian:
      - github-cli            # Use gh (from GitHub's repo)

  # ---------------------------------------------------------------------------
  # PROVIDES: Virtual package -> actual package mapping
  # ---------------------------------------------------------------------------
  # Use when you need a capability but package name varies
  provides:
    vim:
      ubuntu: vim
      debian: vim
      rhel: vim-enhanced
      arch: vim
    
    netcat:
      ubuntu: netcat-openbsd
      debian: netcat-openbsd
      rhel: nmap-ncat
      arch: openbsd-netcat
    
    build_essentials:
      ubuntu: build-essential
      debian: build-essential
      rhel: ['gcc', 'gcc-c++', 'make', 'autoconf', 'automake']
      arch: base-devel        # This is a GROUP on Arch
    
    ssh_client:
      ubuntu: openssh-client
      debian: openssh-client
      rhel: openssh-clients
      arch: openssh           # Unified package
    
    ssh_server:
      ubuntu: openssh-server
      debian: openssh-server
      rhel: openssh-server
      arch: openssh           # Unified package
    
    dns_utils:
      ubuntu: bind9-dnsutils
      debian: bind9-dnsutils
      rhel: bind-utils
      arch: bind
    
    compression_7z:
      ubuntu: 7zip
      debian: 7zip
      rhel: p7zip
      arch: p7zip             # Or 7zip (both work)
    
    github_cli:
      ubuntu: gh
      debian: gh
      rhel: gh
      arch: github-cli        # Different name on Arch!

# =============================================================================
# CAPABILITY: Ubuntu (Debian-family with Ubuntu repos)
# =============================================================================
# Used for: Ubuntu, Kali, Linux Mint, Pop!_OS, Elementary, Zorin
# NOTE: Currently identical to debian section - future consolidation possible
# =============================================================================
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
    - zsh
    - zsh-autosuggestions
    - zsh-syntax-highlighting
  
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

# =============================================================================
# CAPABILITY: Debian (Pure Debian, not derivatives)
# =============================================================================
# NOTE: Currently identical to ubuntu - could merge into apt_common in future
# Kept separate for: potential Debian-specific packages, clarity, easy override
# =============================================================================
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
    - zsh
    - zsh-autosuggestions
    - zsh-syntax-highlighting
  
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

# =============================================================================
# CAPABILITY: RHEL (Red Hat Enterprise Linux family)
# =============================================================================
# Used for: RHEL, CentOS, Rocky Linux, AlmaLinux, Oracle Linux, Fedora
# NOTE: Some packages (duf, ncdu, bat) require EPEL repository
# =============================================================================
rhel:
  core_utils:
    - curl
    - git
    - jq
    - rsync
    - tree
    - unzip
    - vim-enhanced
    - wget
  
  monitoring:
    # NOTE: duf/ncdu need EPEL on RHEL/CentOS
    - htop
    - lsof
    - ltrace
    - strace
    - sysstat
  
  shell_enhancements:
    - bash-completion
    - screen
    - tmux
    - zsh
    # NOTE: zsh plugins typically need manual install or COPR on RHEL
  
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
    - nmap-ncat
    - openssh-clients
    - openssh-server
    - socat
    - tcpdump
    - traceroute
  
  compression:
    - bzip2
    - p7zip
    - p7zip-plugins
    - xz
    - zip
  
  vcs_extras:
    # NOTE: gh needs GitHub's official repo
    - git-lfs
    - tig
  
  modern_cli:
    # NOTE: These need EPEL or manual install on RHEL
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

# =============================================================================
# CAPABILITY: Arch Linux
# =============================================================================
# Used for: Arch, Manjaro, EndeavourOS, Garuda, Artix, ArcoLinux
#
# GOTCHAS:
#   - openssh is UNIFIED (includes both client and server)
#   - libvirt is UNIFIED (includes client and daemon)
#   - base-devel is a PACKAGE GROUP (Salt handles this correctly)
#   - GitHub CLI is 'github-cli', not 'gh'
#   - Use 'fd' not 'fd-find', 'vim' not 'vim-enhanced'
#   - gnupg not gnupg2
# =============================================================================
arch:
  core_utils:
    - curl
    - git
    - jq
    - rsync
    - tree
    - unzip
    - vim              # Not vim-enhanced
    - wget
  
  monitoring:
    - duf              # Available in extra repo
    - htop
    - lsof
    - ltrace
    - ncdu             # Available in extra repo
    - strace
    - sysstat
  
  shell_enhancements:
    - bash-completion
    - screen
    - tmux
    - zsh
    - zsh-autosuggestions      # Available in extra repo
    - zsh-syntax-highlighting  # Available in extra repo
  
  build_tools:
    # NOTE: Could just use 'base-devel' group instead of individual packages
    # Salt can install groups: pkg.installed with name: base-devel
    - autoconf
    - automake
    - base-devel       # GROUP: includes gcc, make, binutils, etc.
    - cmake
  
  networking:
    - bind             # Provides dig, host, nslookup
    - iputils          # Provides ping
    - net-tools
    - nmap
    - openbsd-netcat   # Preferred netcat on Arch
    - openssh          # UNIFIED: client + server + sftp
    - socat
    - tcpdump
    - traceroute
  
  compression:
    - bzip2
    - p7zip            # Single package (or use 7zip)
    - xz
    - zip
  
  vcs_extras:
    - github-cli       # NOT 'gh' - different package name on Arch!
    - git-lfs
    - tig
  
  modern_cli:
    - bat
    - fd               # NOT fd-find
    - fzf
    - ripgrep
  
  security:
    - ca-certificates
    - gnupg            # NOT gnupg2
  
  acl:
    - acl
  
  kvm:
    # NOTE: No cpu-checker on Arch (use /proc/cpuinfo directly)
    # qemu-desktop includes most QEMU components
    - dnsmasq          # Required for libvirt NAT networking
    - edk2-ovmf        # UEFI firmware for VMs
    - libvirt          # UNIFIED: includes daemon, client, etc.
    - qemu-desktop     # Or qemu-full for all architectures
    - virt-install
    - virt-manager     # GUI for libvirt


# =============================================================================
# POWERSHELL GALLERY MODULES
# =============================================================================
# Installed via Install-Module from PowerShell Gallery
# Merged: includes both system modules and user modules
# =============================================================================
powershell_gallery:
  # Core system modules
  - PSReadLine                    # Command-line editing, history, syntax highlighting
  - PowerShellGet                 # Module management (v3+)
  # Winget integration
  - Microsoft.WinGet.Client       # WinGet PowerShell interface
  - Microsoft.WinGet.CommandNotFound  # Command not found suggestions
  # Development & utilities
  - powershell-yaml               # YAML parsing
  - PSFzf                         # Fuzzy finder integration
  - PSWindowsUpdate               # Windows Update management
  - Terminal-Icons                # File icons in terminal

# =============================================================================
# CHOCOLATEY PACKAGES
# =============================================================================
choco:
  # Core extensions
  - chocolatey-core.extension
  - chocolatey-compatibility.extension
  - chocolatey-font-helpers.extension
  # Container
  - dive
  - docker-cli
  - docker-compose
  # Editor / Font
  - vim
  - nerd-fonts-FiraCode
  - nerd-fonts-Hack
  - Cygwin
  - colortool
  # FIXME: Rsync fails every time not sure why may be build
  # - rsync
  # Gaming
  - cheatengine
  # Build
  - make

# =============================================================================
# WINGET RUNTIMES
# =============================================================================
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

# =============================================================================
# WINGET SYSTEM PACKAGES ( EXE )
# =============================================================================
winget_system:
  sync_backup:
    - Microsoft.OneDrive
  hardware:
    - Guru3D.RTSS
    - Rem0o.FanControl
    - TechPowerUp.NVCleanstall
    - BitSum.ParkControl
    - BitSum.ProcessLasso
    - Wagnardsoft.DisplayDriverUninstaller
  networking:
    - Apple.Bonjour
    - SSHFS-Win.SSHFS-Win
    - WinFsp.WinFsp
    - Insecure.Nmap
    - WiresharkFoundation.Wireshark
  shells:
    - Microsoft.PowerShell
    - Starship.Starship
  rgb_peripherals:
    - OpenRGB.OpenRGB
    - Olivia.VIA
    - namazso.PawnIO
    - Nefarius.HidHide
    - ViGEm.ViGEmBus
  ricing:
    - Rainmeter.Rainmeter
  dev_tools:
    - GitHub.cli
    - MSYS2.MSYS2
    - Git.Git
  system_utilities:
    - 7zip.7zip
    - CodeSector.TeraCopy
  gaming:
    - Valve.Steam
  browsers:
    - Microsoft.Edge
    - Google.Chrome.EXE
  kubernetes:
    - Kubecolor.kubecolor
  media_creative:
    - Inkscape.Inkscape
    - Cockos.REAPER
    - Audacity.Audacity
    - rocksdanister.LivelyWallpaper
    - KDE.Krita

# =============================================================================
# WINGET USERLAND PACKAGES ( MSXI )
# =============================================================================
winget_userland:
  sync_backup:
    - Microsoft.OneDrive
    - Martchus.syncthingtray
  hardware:
    - LibreHardwareMonitor.LibreHardwareMonitor
  networking:
    - evsar3.sshfs-win-manager
  shells:
    - Microsoft.AIShell
    - JanDeDobbeleer.OhMyPosh
    - Microsoft.WindowsTerminal
  communication:
    - hoppscotch.Hoppscotch
    - Vencord.Vesktop
    - Microsoft.Teams
  rgb_peripherals:
    - Nefarius.HidHide
  office:
    - Obsidian.Obsidian
  dev_tools:
    - Microsoft.VisualStudioCode
    - Microsoft.VisualStudioCode.Insiders
    - direnv.direnv
    - jqlang.jq
    - DenoLand.Deno
    - Hashicorp.Terraform
    - Hashicorp.TerraformLanguageServer
    - junegunn.fzf
    - Microsoft.VisualStudioCode.CLI
    - Microsoft.VisualStudioCode.Insiders.CLI
    - nektos.act
    - waterlan.dos2unix
  system_utilities:
    - Microsoft.PowerToys
    - AntibodySoftware.WizTree
    - WinSCP.WinSCP
    - Rufus.Rufus
    - Microsoft.Sysinternals.Autoruns
    - Microsoft.Sysinternals.ProcessExplorer
    - Rclone.Rclone
    - Ventoy.Ventoy
  gaming:
    - Playnite.Playnite
    - SpecialK.SpecialK
    - HeroicGamesLauncher.HeroicGamesLauncher
    - mtkennerly.ludusavi
  kubernetes:
    - Kubernetes.kubectl
    - Helm.Helm
    - stern.stern
  desktop_customization:
    - AutoHotkey.AutoHotkey
    - File-New-Project.EarTrumpet
  media_creative:
    - yt-dlp.yt-dlp
    - Gyan.FFmpeg

# =============================================================================
# PIP PACKAGES (via miniforge/uv)
# =============================================================================
# Installed in miniforge base environment - same across all platforms via uv
pip_base:
  - 'uv'
  - 'git-filter-repo'
  - 'ipython'
  - 'pylance'
  - 'pylint'
  - 'ruff'
  - 'yamllint'

# =============================================================================
# NPM GLOBAL PACKAGES (via nvm)
# =============================================================================
# Same across all platforms - applied after nvm installs Node.js
npm_global:
  - '@types/node'
  - 'eslint'
  - 'markdownlint'
  - 'prettier'
  - 'ts-node'
  - 'typescript-language-server'
  - 'typescript'
  - 'yarn'
