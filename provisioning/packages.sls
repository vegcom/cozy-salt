distro_aliases:
  kali: ubuntu
  linuxmint: ubuntu
  pop: ubuntu
  elementary: ubuntu
  zorin: ubuntu
  rocky: rhel
  alma: rhel
  almalinux: rhel
  centos: rhel
  fedora: rhel
  oracle: rhel
  scientific: rhel
  manjaro: arch
  endeavouros: arch
  garuda: arch
  artix: arch
  arcolinux: arch
package_metadata:
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
arch:
  core_utils:
    - curl
    - git
    - jq
    - rsync
    - tree
    - unzip
    - wget
    - sed
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
    - base-devel
    - cmake
  networking:
    - bind
    - iputils
    - net-tools
    - nmap
    - openbsd-netcat
    - openssh
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
    - github-cli
    - git-lfs
    - tig
  modern_cli:
    - bat
    - fd
    - fzf
    - ripgrep
  security:
    - ca-certificates
    - gnupg
  acl:
    - acl
  kvm:
    - dnsmasq
    - edk2-ovmf
    - libvirt
    - qemu-desktop
    - virt-install
    - virt-manager
  interpreters:
    - lua
    - perl
    - python
    - python-pip
  shell_history:
    - atuin
  modern_cli_extras:
    - bottom
    - delta git diff pager (better diffs)
    - eza ls replacement (replaces exa)
    - hyperfine Benchmarking tool
    - procs ps replacement
    - tealdeer tldr pages alternative (tldr command)
    - tokei Code stats / line counter
    - zoxide cd replacement with frecency
  fonts:
    - noto-fonts
    - noto-fonts-emoji
    - ttf-fira-code Developer font
    - ttf-hack Developer font
    - ttf-jetbrains-mono Developer font
  theming:
    - arc-gtk-theme GTK theme
    - kvantum Qt theme engine
    - papirus-icon-theme Icon theme
powershell_gallery:
  - PSReadLine Command-line editing, history, syntax highlighting
  - PowerShellGet Module management (v3+)
  - Microsoft.WinGet.Client WinGet PowerShell interface
  - Microsoft.WinGet.CommandNotFound Command not found suggestions
  - powershell-yaml YAML parsing
  - PSFzf Fuzzy finder integration
  - PSWindowsUpdate Windows Update management
  - Terminal-Icons File icons in terminal
choco:
  - chocolatey-core.extension
  - chocolatey-compatibility.extension
  - chocolatey-font-helpers.extension
  - dive
  - docker-cli
  - docker-compose
  - vim
  - nerd-fonts-FiraCode
  - nerd-fonts-Hack
  - Cygwin
  - colortool
  - cheatengine
  - make
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
pip_base:
  - 'uv'
  - 'git-filter-repo'
  - 'ipython'
  - 'pylance'
  - 'pylint'
  - 'ruff'
  - 'yamllint'
npm_global:
  - '@types/node'
  - 'markdownlint'
  - 'prettier'
  - 'ts-node'
  - 'typescript-language-server'
  - 'typescript'
  - 'yarn'
