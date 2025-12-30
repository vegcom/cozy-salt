# P2 Draft: Capability-Based Package Groups with Distro Mapping
# 
# Strategy: Group packages by PURPOSE/CAPABILITY, then map to available names per distro
# This avoids listing unavailable packages and makes it clear what role each package plays

packages:
  # =========================================================================
  # CAPABILITY: Core Utilities
  # =========================================================================
  core_utils:
    description: Essential tools every system needs
    apt:
      - curl
      - wget
      - git
      - vim
      - rsync
      - jq
      - tree
      - unzip
    dnf:
      - curl
      - wget
      - git
      - vim-enhanced
      - rsync
      - jq
      - tree
      - unzip

  # =========================================================================
  # CAPABILITY: System Monitoring & Diagnostics
  # =========================================================================
  monitoring:
    description: Tools for viewing system health, processes, logs
    apt:
      - htop          # Interactive process viewer
      - lsof
      - strace
      - ltrace
      - sysstat
      - duf           # Disk usage (modern df alternative)
      - ncdu          # Disk usage analyzer
    dnf:
      # Note: These may not be in base repos, may need EPEL
      - htop
      - lsof
      - strace
      - ltrace
      - sysstat
      # duf: Not in RHEL base, available via source
      # ncdu: Not in RHEL base, available via source
      
  # =========================================================================
  # CAPABILITY: Shell Customization
  # =========================================================================
  shell_enhancements:
    description: Shell extensions, completions, syntax highlighting
    apt:
      - zsh
      - bash-completion
      - zsh-autosuggestions
      - zsh-syntax-highlighting
      - tmux
      - screen
    dnf:
      - zsh
      - bash-completion
      # zsh-autosuggestions: May be in EPEL or requires manual install
      # zsh-syntax-highlighting: May be in EPEL or requires manual install
      - tmux
      - screen

  # =========================================================================
  # CAPABILITY: Development & Build Tools
  # =========================================================================
  build_tools:
    description: Compilers, build systems, dependency tools
    apt:
      - build-essential
      - cmake
      - pkg-config
      - autoconf
      - automake
    dnf:
      - gcc
      - gcc-c++
      - make
      - cmake
      - pkgconfig
      - autoconf
      - automake

  # =========================================================================
  # CAPABILITY: Modern CLI Tools (Rust-based, etc)
  # =========================================================================
  modern_cli:
    description: New generation command-line tools (ripgrep, fd, etc)
    apt:
      # All available in Debian repos
      - ripgrep
      - fd-find
      - bat
      - fzf
    dnf:
      # These may not be in RHEL base repos
      # ripgrep: Not in base, available via COPR or compile
      # fd: Not in base, available via COPR or compile
      # bat: Not in base, available via COPR or compile
      - fzf           # Fuzzy finder (in EPEL)

  # =========================================================================
  # CAPABILITY: Networking & Security
  # =========================================================================
  networking:
    description: Network tools, SSH, DNS utilities, port scanners
    apt:
      - openssh-client
      - openssh-server
      - net-tools
      - iputils-ping
      - bind9-dnsutils
      - netcat-openbsd
      - socat
      - traceroute
      - tcpdump
      - nmap
    dnf:
      - openssh-clients
      - openssh-server
      - net-tools
      - iputils
      - bind-utils
      - nmap-ncat
      - socat
      - traceroute
      - tcpdump
      - nmap

  # =========================================================================
  # CAPABILITY: Compression & Archives
  # =========================================================================
  compression:
    description: Archive tools, compression utilities
    apt:
      - zip
      - 7zip
      - bzip2
      - xz-utils
    dnf:
      - zip
      - p7zip
      - p7zip-plugins
      - bzip2
      - xz

  # =========================================================================
  # CAPABILITY: Version Control Extras
  # =========================================================================
  vcs_extras:
    description: Enhanced git tools, GitHub CLI
    apt:
      - git-lfs
      - tig
      - gh              # GitHub CLI (may need PPA on older Debian)
    dnf:
      - git-lfs
      - tig
      - gh              # May need COPR on RHEL

  # =========================================================================
  # CAPABILITY: Security & Certificates
  # =========================================================================
  security:
    description: CA certificates, crypto tools
    apt:
      - ca-certificates
    dnf:
      - gnupg2
      - ca-certificates

  # =========================================================================
  # CAPABILITY: System Access Control
  # =========================================================================
  acl:
    description: Access control lists and permissions
    apt:
      - acl
    dnf:
      - acl

  # =========================================================================
  # CAPABILITY: KVM & Virtualization (Optional - test hosts only)
  # =========================================================================
  kvm_optional:
    description: Virtualization tools for Windows testing via Dockur
    apt:
      - qemu-system-x86
      - qemu-utils
      - cpu-checker
      - libvirt-daemon-system
      - libvirt-clients
      - virtinst
    dnf:
      - qemu-kvm
      - qemu-img
      - qemu-kvm-tools
      - cpu-checker
      - libvirt
      - libvirt-daemon
      - libvirt-client
      - virt-install

  # =========================================================================
  # NPM GLOBAL PACKAGES (via nvm)
  # =========================================================================
  npm_global:
    description: Global npm packages (same across all platforms)
    packages:
      - '@anthropic-ai/claude-code'
      - 'pnpm'
      - 'yarn'
      - 'typescript'
      - 'ts-node'
      - '@types/node'
      - 'prettier'
      - 'eslint'

  # =========================================================================
  # WINDOWS PACKAGES (Chocolatey)
  # =========================================================================
  choco:
    description: Chocolatey packages (Windows primary)
    packages:
      - chocolatey-core.extension
      - chocolatey-compatibility.extension
      - chocolatey-font-helpers.extension
      - vim
      - FiraCode
      - nerd-fonts-FiraCode
      - nerd-fonts-Hack
      - Cygwin
      - colortool
      - rsync
      - cheatengine
      - make

  # =========================================================================
  # WINDOWS PACKAGES (Winget - Secondary)
  # =========================================================================
  winget:
    description: Winget packages (use when not in Chocolatey)
    dev_tools:
      - CoreyButler.NVMforWindows
      - DenoLand.Deno
      - Anaconda.Miniconda3
      - Git.Git
      - GitHub.cli
      - Neovim.Neovim
      - Microsoft.VisualStudioCode.Insiders
      - Hashicorp.Terraform
      - jqlang.jq
      - junegunn.fzf
    shells:
      - Starship.Starship
      - JanDeDobbeleer.OhMyPosh
      - Microsoft.WindowsTerminal
      - Microsoft.PowerShell.Preview
    utilities:
      - 7zip.7zip
      - WinSCP.WinSCP
      - Rclone.Rclone
    system:
      - REALiX.HWiNFO
      - LibreHardwareMonitor.LibreHardwareMonitor
      - BitSum.ProcessLasso
      - TechPowerUp.NVCleanstall
    networking:
      - Tailscale.Tailscale
      - SSHFS-Win.SSHFS-Win
      - Insecure.Nmap
    gaming:
      - Valve.Steam
      - Playnite.Playnite
    media:
      - Audacity.Audacity
      - Gyan.FFmpeg
      - yt-dlp.yt-dlp
    browsers:
      - Google.Chrome.EXE
      - Microsoft.Edge


# =========================================================================
# AVAILABILITY NOTES FOR P2 IMPLEMENTATION
# =========================================================================
#
# RHEL/dnf packages NOT in base repos (may need EPEL, COPR, or manual install):
#   - zsh-autosuggestions, zsh-syntax-highlighting (EPEL or manual)
#   - ripgrep, fd, bat, duf, ncdu (COPR or compile from source)
#   - gh (GitHub CLI) (COPR)
#
# Debian/apt packages always available:
#   - All listed packages available in Debian bullseye+ and Ubuntu 20.04+
#
# Usage in states:
#   Instead of: {{ packages.apt }} or {{ packages.dnf }}
#   Use: {{ packages[target_os].core_utils }} where target_os is determined by grains
#
# Implementation strategy:
#   1. Import this file as "packages_p2"
#   2. In states, select packages based on grains.os_family
#   3. Group installs by capability (not all at once)
#   4. Document EPEL/COPR requirements in README
