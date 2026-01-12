# Capability-Based Package Configuration (P2)
# Organized by PURPOSE/ROLE, with per-distro package mapping
#
# In states use: import_yaml 'provisioning/packages.sls' as packages
# Then select packages: packages.core_utils[os_name] where os_name is ubuntu/debian/rhel

# =============================================================================
# CAPABILITY: Ubuntu
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
# CAPABILITY: Debian
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
# CAPABILITY: Rhel
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
    - cpu-checker
    - libvirt
    - libvirt-client
    - libvirt-daemon
    - qemu-img
    - qemu-kvm
    - qemu-kvm-tools
    - virt-install


# =============================================================================
# CAPABILITY: Archlinux
# =============================================================================
# FIXME: actually a 1:1 copy of rhel names not evaluated at this time
archlinux:
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
    - cpu-checker
    - libvirt
    - libvirt-client
    - libvirt-daemon
    - qemu-img
    - qemu-kvm
    - qemu-kvm-tools
    - virt-install

# =============================================================================
# Add-AppxPackage
# =============================================================================
appx_package:
  # FIXME: May not be required https://github.com/microsoft/terminal/issues/18033
  # TODO: Eval for Microsoft.UI.Xaml.2.8 requirement here rather than winget
  - stub_item

# =============================================================================
# Power Shell system modules
# =============================================================================
powershell_modules:
  - PSReadLine
  - powershell-yaml

powershell_gallery:
  - Terminal-Icons
  - PSWindowsUpdate
  - PowerShellGet
  - Microsoft.WinGet.Client
  - Microsoft.WinGet.CommandNotFound
  - PSFzf

# =============================================================================
# CHOCOLATEY PACKAGES
# =============================================================================
choco:
  # Core
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
  #FIXME: Rsync fails every time not sure why may be build
  #- rsync
  # Gaming
  - cheatengine
  # build
  - make

# =============================================================================
# WINGET: RUNTIMES & FRAMEWORKS
# =============================================================================
winget_runtimes:
  dotnet:
    - Microsoft.DotNet.AspNetCore.9
    - Microsoft.DotNet.DesktopRuntime.10
    - Microsoft.DotNet.DesktopRuntime.8
    - Microsoft.DotNet.DesktopRuntime.9
    - Microsoft.DotNet.Framework.DeveloperPack.4.6
    - Microsoft.DotNet.HostingBundle.8
    - Microsoft.DotNet.Runtime.10
    - Microsoft.DotNet.Runtime.8
  vcredist:
    - Microsoft.VCRedist.2008.x64
    - Microsoft.VCRedist.2008.x86
    - Microsoft.VCRedist.2010.x64
    - Microsoft.VCRedist.2010.x86
    - Microsoft.VCRedist.2012.x64
    - Microsoft.VCRedist.2012.x86
    - Microsoft.VCRedist.2013.x64
    - Microsoft.VCRedist.2013.x86
    - Microsoft.VCRedist.2015+.x64
    - Microsoft.VCRedist.2015+.x86
  ui_libraries:
    - Microsoft.UI.Xaml.2.7
    - Microsoft.UI.Xaml.2.8
    - Microsoft.VCLibs.Desktop.14
  sdks:
    - Microsoft.AppInstaller
    - Microsoft.AppInstallerFileBuilder
    - Microsoft.NuGet
    - Microsoft.WindowsADK
    - Microsoft.WindowsSDK.10.0.18362

# =============================================================================
# WINGET PACKAGES
# =============================================================================
winget_system:
  dev_tools:
    - Git.Git
    - GitHub.cli
    - MSYS2.MSYS2
  kubernetes:
    - Kubecolor.kubecolor
  shells:
    - Microsoft.PowerShell
    - Starship.Starship
  system_utilities:
    - 7zip.7zip
    - CodeSector.TeraCopy
  hardware:
    - BitSum.ParkControl
    - BitSum.ProcessLasso
    - Guru3D.RTSS
    - Rem0o.FanControl
    - TechPowerUp.NVCleanstall
    - Wagnardsoft.DisplayDriverUninstaller
  rgb_peripherals:
    - namazso.PawnIO
    - Nefarius.HidHide
    - Olivia.VIA
    - OpenRGB.OpenRGB
    - ViGEm.ViGEmBus
  networking:
    - Apple.Bonjour
    - Insecure.Nmap
    - SSHFS-Win.SSHFS-Win
    - WinFsp.WinFsp
    - WiresharkFoundation.Wireshark
  gaming:
    - Valve.Steam
  sync_backup:
    - Microsoft.OneDrive
  media_creative:
    - Audacity.Audacity
    - Cockos.REAPER
    - Inkscape.Inkscape
    - KDE.Krita
    - rocksdanister.LivelyWallpaper
  browsers:
    - Google.Chrome.EXE
    - Microsoft.Edge
  ricing:
    - Rainmeter.Rainmeter

# =============================================================================
# WINGET: Userland Configuration for Winget Package Manager
# =============================================================================
winget_userland:
  dev_tools:
    - DenoLand.Deno
    - direnv.direnv
    - Hashicorp.Terraform
    - Hashicorp.TerraformLanguageServer
    - jqlang.jq
    - junegunn.fzf
    - Microsoft.VisualStudioCode
    - Microsoft.VisualStudioCode.CLI
    - Microsoft.VisualStudioCode.Insiders
    - Microsoft.VisualStudioCode.Insiders.CLI
    - nektos.act
    - waterlan.dos2unix
  kubernetes:
    - Helm.Helm
    - Kubernetes.kubectl
    - stern.stern
  shells:
    - JanDeDobbeleer.OhMyPosh
    - Microsoft.AIShell
    - Microsoft.WindowsTerminal
  system_utilities:
    - AntibodySoftware.WizTree
    - Microsoft.PowerToys
    - Microsoft.Sysinternals.Autoruns
    - Microsoft.Sysinternals.ProcessExplorer
    - Rclone.Rclone
    - Rufus.Rufus
    - Ventoy.Ventoy
    - WinSCP.WinSCP
  hardware:
    - LibreHardwareMonitor.LibreHardwareMonitor
  rgb_peripherals:
    - Nefarius.HidHide
  networking:
  - evsar3.sshfs-win-manager
  gaming:
    - HeroicGamesLauncher.HeroicGamesLauncher
    - mtkennerly.ludusavi
    - Playnite.Playnite
    - SpecialK.SpecialK
  media_creative:
    - Gyan.FFmpeg
    - yt-dlp.yt-dlp
  communication:
    - hoppscotch.Hoppscotch
    - Microsoft.Teams
    - Vencord.Vesktop
  sync_backup:
    - Martchus.syncthingtray
    - Microsoft.OneDrive
  desktop_customization:
    - AutoHotkey.AutoHotkey
    - File-New-Project.EarTrumpet
  office:
    - Obsidian.Obsidian

# =============================================================================
# PIP BASE PACKAGES (via miniforge)
# =============================================================================
# Installed in miniforge base environment - same across all platforms
# uvx = npx for Python (run CLI tools in isolated envs)
pip_base:
  - 'black'
  - 'git-filter-repo'
  - 'ipython'
  - 'pylance'
  - 'pylint'
  - 'ruff'
  - 'uv'
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
