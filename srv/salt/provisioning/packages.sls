# Capability-Based Package Configuration (P2)
# Organized by PURPOSE/ROLE, with per-distro package mapping
#
# WARNING: DO NOT use Jinja2 tag syntax in comments (causes rendering errors)
# This file is imported by salt states as YAML
#
# In states use: import_yaml 'provisioning/packages.sls' as packages
# Then select packages: packages.core_utils[os_name] where os_name is ubuntu/debian/rhel
#
# See provisioning/packages-p2-draft.sls for detailed notes

# =============================================================================
# CAPABILITY: Core Utilities
# =============================================================================
core_utils:
  ubuntu:
    - curl
    - wget
    - git
    - vim
    - rsync
    - jq
    - tree
    - unzip
  debian:
    - curl
    - wget
    - git
    - vim
    - rsync
    - jq
    - tree
    - unzip
  rhel:
    - curl
    - wget
    - git
    - vim-enhanced
    - rsync
    - jq
    - tree
    - unzip

# =============================================================================
# CAPABILITY: System Monitoring & Diagnostics  
# =============================================================================
monitoring:
  ubuntu:
    - htop
    - lsof
    - strace
    - ltrace
    - sysstat
    - duf
    - ncdu
  debian:
    - htop
    - lsof
    - strace
    - ltrace
    - sysstat
    - duf
    - ncdu
  rhel:
    # Note: Many not in base repos, may need EPEL
    - htop
    - lsof
    - strace
    - ltrace
    - sysstat

# =============================================================================
# CAPABILITY: Shell Customization & Enhancements
# =============================================================================
shell_enhancements:
  ubuntu:
    - zsh
    - bash-completion
    - zsh-autosuggestions
    - zsh-syntax-highlighting
    - tmux
    - screen
  debian:
    - zsh
    - bash-completion
    - zsh-autosuggestions
    - zsh-syntax-highlighting
    - tmux
    - screen
  rhel:
    # Note: zsh-autosuggestions/zsh-syntax-highlighting may need EPEL
    - zsh
    - bash-completion
    - tmux
    - screen

# =============================================================================
# CAPABILITY: Build Tools & Compilers
# =============================================================================
build_tools:
  ubuntu:
    - build-essential
    - cmake
    - pkg-config
    - autoconf
    - automake
  debian:
    - build-essential
    - cmake
    - pkg-config
    - autoconf
    - automake
  rhel:
    - gcc
    - gcc-c++
    - make
    - cmake
    - autoconf
    - automake

# =============================================================================
# CAPABILITY: Networking & Communication Tools
# =============================================================================
networking:
  ubuntu:
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
  debian:
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
  rhel:
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

# =============================================================================
# CAPABILITY: Compression & Archive Tools
# =============================================================================
compression:
  ubuntu:
    - zip
    - 7zip
    - bzip2
    - xz-utils
  debian:
    - zip
    - 7zip
    - bzip2
    - xz-utils
  rhel:
    - zip
    - p7zip
    - p7zip-plugins
    - bzip2
    - xz

# =============================================================================
# CAPABILITY: Version Control Extras
# =============================================================================
vcs_extras:
  ubuntu:
    - git-lfs
    - tig
    - gh
  debian:
    - git-lfs
    - tig
    - gh
  rhel:
    - git-lfs
    - tig
    # gh (GitHub CLI) may need COPR on RHEL

# =============================================================================
# CAPABILITY: Modern CLI Tools (Rust-based & others)
# =============================================================================
# WARNING: Many of these are NOT in RHEL base repos
# Consider them OPTIONAL for RHEL without external repos (COPR, etc)
modern_cli:
  ubuntu:
    - ripgrep
    - fd-find
    - bat
    - fzf
  debian:
    - ripgrep
    - fd-find
    - bat
    - fzf
  rhel:
    # These may not be in base repos:
    # - ripgrep  (available via COPR or compile)
    # - fd  (available via COPR or compile)
    # - bat  (available via COPR or compile)
    - fzf  # Fuzzy finder (in EPEL)

# =============================================================================
# CAPABILITY: Security & Certificates
# =============================================================================
security:
  ubuntu:
    - ca-certificates
  debian:
    - ca-certificates
  rhel:
    - gnupg2
    - ca-certificates

# =============================================================================
# CAPABILITY: Access Control Lists
# =============================================================================
acl:
  ubuntu:
    - acl
  debian:
    - acl
  rhel:
    - acl

# =============================================================================
# CAPABILITY: KVM & Virtualization (Optional - test hosts only)
# =============================================================================
kvm:
  ubuntu:
    - qemu-system-x86
    - qemu-utils
    - cpu-checker
    - libvirt-daemon-system
    - libvirt-clients
    - virtinst
  debian:
    - qemu-system-x86
    - qemu-utils
    - cpu-checker
    - libvirt-daemon-system
    - libvirt-clients
    - virtinst
  rhel:
    - qemu-kvm
    - qemu-img
    - qemu-kvm-tools
    - cpu-checker
    - libvirt
    - libvirt-daemon
    - libvirt-client
    - virt-install

# =============================================================================
# NPM GLOBAL PACKAGES (via nvm)
# =============================================================================
# Same across all platforms - applied after nvm installs Node.js
npm_global:
  - '@anthropic-ai/claude-code'
  - 'pnpm'
  - 'yarn'
  - 'typescript'
  - 'ts-node'
  - '@types/node'
  - 'prettier'
  - 'eslint'

# =============================================================================
# CHOCOLATEY PACKAGES (Windows Primary)
# =============================================================================
choco:
  - chocolatey-core.extension
  - chocolatey-compatibility.extension
  - chocolatey-font-helpers.extension
  - dive
  - docker-cli
  - docker-compose
  - vim
  - FiraCode
  - nerd-fonts-FiraCode
  - nerd-fonts-Hack
  - Cygwin
  - colortool
  - rsync
  - cheatengine
  - make

# =============================================================================
# WINGET PACKAGES (Windows Secondary)
# =============================================================================
winget:
  dev_tools:
    - CoreyButler.NVMforWindows
    - DenoLand.Deno
    - Anaconda.Miniconda3
    - Git.Git
    - GitHub.cli
    - Neovim.Neovim
    - Microsoft.VisualStudioCode.Insiders
    - Hashicorp.Terraform
    - Hashicorp.TerraformLanguageServer
    - nektos.act
    - jqlang.jq
    - junegunn.fzf
    - direnv.direnv
    - waterlan.dos2unix
  kubernetes:
    - Kubernetes.kubectl
    - Kubernetes.minikube
    - Helm.Helm
    - Kubecolor.kubecolor
    - stern.stern
  shells:
    - Starship.Starship
    - JanDeDobbeleer.OhMyPosh
    - Microsoft.WindowsTerminal
    - Microsoft.PowerShell.Preview
    - Microsoft.AIShell
  system_utilities:
    - 7zip.7zip
    - AntibodySoftware.WizTree
    - CodeSector.TeraCopy
    - Rufus.Rufus
    - Ventoy.Ventoy
    - WinSCP.WinSCP
    - Rclone.Rclone
    - Microsoft.Sysinternals.Autoruns
    - Microsoft.Sysinternals.ProcessExplorer
    - Microsoft.PowerToys
  hardware:
    - REALiX.HWiNFO
    - LibreHardwareMonitor.LibreHardwareMonitor
    - Rem0o.FanControl
    - Guru3D.Afterburner
    - Guru3D.RTSS
    - BitSum.ProcessLasso
    - BitSum.ParkControl
    - TechPowerUp.NVCleanstall
    - Wagnardsoft.DisplayDriverUninstaller
  rgb_peripherals:
    - OpenRGB.OpenRGB
    - OpenRGB.OpenRGBEffectsPlugin
    - OpenRGB.OpenRGBHardwareSyncPlugin
    - OpenRGB.OpenRGBVisualMapPlugin
    - Olivia.VIA
    - Ryochan7.DS4Windows
    - ViGEm.ViGEmBus
    - Nefarius.HidHide
    - namazso.PawnIO
  networking:
    - Tailscale.Tailscale
    - SSHFS-Win.SSHFS-Win
    - evsar3.sshfs-win-manager
    - WinFsp.WinFsp
    - Insecure.Nmap
    - WiresharkFoundation.Wireshark
    - Apple.Bonjour
  gaming:
    - Valve.Steam
    - Valve.SteamCMD
    - Playnite.Playnite
    - HeroicGamesLauncher.HeroicGamesLauncher
    - Beyond-All-Reason.Beyond-All-Reason
    - SpecialK.SpecialK
    - mtkennerly.ludusavi
  media_creative:
    - Audacity.Audacity
    - KDE.Krita
    - Gyan.FFmpeg
    - yt-dlp.yt-dlp
    - Inkscape.Inkscape
    - rocksdanister.LivelyWallpaper
  communication:
    - Vencord.Vesktop
    - Proton.ProtonMailBridge
    - Microsoft.Teams
    - Obsidian.Obsidian
    - hoppscotch.Hoppscotch
  file_transfer:
    - Transmission.Transmission
    - DelugeTeam.Deluge
  sync_backup:
    - Martchus.syncthingtray
    - Microsoft.OneDrive
  desktop_customization:
    - AutoHotkey.AutoHotkey
    - File-New-Project.EarTrumpet
  browsers:
    - Google.Chrome.EXE
    - Microsoft.Edge

# =============================================================================
# WINGET: RUNTIMES & FRAMEWORKS
# =============================================================================
winget_runtimes:
  dotnet:
    - Microsoft.DotNet.Runtime.8
    - Microsoft.DotNet.Runtime.10
    - Microsoft.DotNet.DesktopRuntime.8
    - Microsoft.DotNet.DesktopRuntime.9
    - Microsoft.DotNet.DesktopRuntime.10
    - Microsoft.DotNet.AspNetCore.9
    - Microsoft.DotNet.HostingBundle.8
    - Microsoft.DotNet.Framework.DeveloperPack.4.6
  vcredist:
    - Microsoft.VCRedist.2008.x86
    - Microsoft.VCRedist.2008.x64
    - Microsoft.VCRedist.2010.x86
    - Microsoft.VCRedist.2010.x64
    - Microsoft.VCRedist.2012.x86
    - Microsoft.VCRedist.2012.x64
    - Microsoft.VCRedist.2013.x86
    - Microsoft.VCRedist.2013.x64
    - Microsoft.VCRedist.2015+.x86
    - Microsoft.VCRedist.2015+.x64
  ui_libraries:
    - Microsoft.UI.Xaml.2.7
    - Microsoft.UI.Xaml.2.8
    - Microsoft.VCLibs.Desktop.14
  sdks:
    - Microsoft.WindowsSDK.10.0.18362
    - Microsoft.WindowsADK
    - Microsoft.NuGet
