#!jinja|yaml
# Package Definitions for cozy-salt
# See docs/package-management.md for usage and architecture
#
# Structure: distro_aliases, package_metadata, per-distro packages, windows, pip/npm/brew
# Capability groups: core_utils, shell_enhancements, monitoring, compression, vcs_extras,
#                    modern_cli, security, acl, build_tools, networking, kvm
# Arch-only: modern_cli_extras, interpreters, fonts, theming

# ============================================================================
# SHARED PACKAGE LISTS (DRY - referenced by distro sections below)
# ============================================================================
{% set _core = ['curl', 'git', 'jq', 'rsync', 'tree', 'unzip', 'wget'] %}
{% set _monitoring_base = ['htop', 'lsof', 'ltrace', 'strace', 'sysstat'] %}
{% set _shell = ['bash-completion', 'screen', 'tmux', 'shellcheck'] %}
{% set _build_base = ['autoconf', 'automake', 'cmake'] %}
{% set _net_base = ['nmap', 'socat', 'tcpdump', 'traceroute', 'avahi'] %}
{% set _compress_base = ['bzip2', 'zip'] %}
{% set _vcs_base = ['git-lfs', 'tig'] %}
{% set _modern_cli_base = ['bat', 'fzf', 'ripgrep'] %}

# ============================================================================
# APT-BASED (Debian/Ubuntu) - single definition, both reference it
# ============================================================================
{% set _apt = {
    'core_utils': _core + ['vim'],
    'monitoring': _monitoring_base + ['duf', 'ncdu'],
    'shell_enhancements': _shell,
    'build_tools': _build_base + ['build-essential', 'pkg-config'],
    'networking': _net_base + ['bind9-dnsutils', 'iputils-ping', 'net-tools', 'netcat-openbsd', 'openssh-client', 'openssh-server'],
    'compression': _compress_base + ['7zip', 'xz-utils'],
    'vcs_extras': _vcs_base + ['gh'],
    'modern_cli': _modern_cli_base + ['fd-find'],
    'security': ['ca-certificates'],
    'acl': ['acl'],
    'kvm': ['cpu-checker', 'libvirt-clients', 'libvirt-daemon-system', 'qemu-system-x86', 'qemu-utils', 'virtinst'],
} %}

# ============================================================================
# DISTRO ALIAS MAPPING
# ============================================================================
distro_aliases:
  ubuntu: ubuntu
  ubuntu-wsl: ubuntu
  wsl: ubuntu
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

# ============================================================================
# PACKAGE METADATA
# ============================================================================
package_metadata:
  conflicts:
    database_mysql: [mysql, mariadb, percona-server]
    java_17_jdk: [openjdk-17-jdk, java-17-openjdk-devel, jdk17-openjdk]
    java_21_jdk: [openjdk-21-jdk, java-21-openjdk-devel, jdk21-openjdk]
    netcat_variants: [netcat-openbsd, nmap-ncat, openbsd-netcat, gnu-netcat]
    mta: [postfix, sendmail, exim4]
    container_runtime: [docker-ce, podman, containerd]
    firewall: [ufw, firewalld, iptables-persistent]

  optional:
    modern_cli_tools: [bat, fd, ripgrep, fzf, duf, ncdu, eza, delta, zoxide]
    dev_extras: [gh, git-lfs, tig, lazygit]
    shell_extras: [zsh-autosuggestions, zsh-syntax-highlighting, starship]

  required:
    core: [curl, git, openssh, ca-certificates]
    build: [gcc, make]
    network: [ping, traceroute, dig, avahi]

  exclude:
    arch: [cpu-checker, build-essential, openssh-client, openssh-server, vim-enhanced, fd-find, gnupg2]
    rhel: [duf, ncdu]
    debian: [github-cli]

  provides:
    vim: {ubuntu: vim, debian: vim, rhel: vim-enhanced, arch: vim}
    avahi: {ubuntu: avahi-daemon, debian: avahi-daemon, rhel: avahi, arch: avahi}
    netcat: {ubuntu: netcat-openbsd, debian: netcat-openbsd, rhel: nmap-ncat, arch: openbsd-netcat}
    build_essentials: {ubuntu: build-essential, debian: build-essential, rhel: ['gcc', 'gcc-c++', 'make', 'autoconf', 'automake'], arch: base-devel}
    ssh_client: {ubuntu: openssh-client, debian: openssh-client, rhel: openssh-clients, arch: openssh}
    ssh_server: {ubuntu: openssh-server, debian: openssh-server, rhel: openssh-server, arch: openssh}
    dns_utils: {ubuntu: bind9-dnsutils, debian: bind9-dnsutils, rhel: bind-utils, arch: bind}
    compression_7z: {ubuntu: 7zip, debian: 7zip, rhel: p7zip, arch: p7zip}
    github_cli: {ubuntu: gh, debian: gh, rhel: gh, arch: github-cli}
    shellcheck: {ubuntu: shellcheck, debian: shellcheck, rhel: ShellCheck, arch: shellcheck}

# ============================================================================
# DEBIAN/UBUNTU PACKAGES (apt-based, identical)
# ============================================================================
debian: {{ _apt | tojson }}
ubuntu: {{ _apt | tojson }}

# ============================================================================
# RHEL PACKAGES (dnf/yum - different pkg names, no duf/ncdu in base repos)
# ============================================================================
rhel:
  core_utils: {{ (_core + ['vim-enhanced']) | tojson }}
  monitoring: {{ _monitoring_base | tojson }}
  shell_enhancements: {{ _shell | tojson }}
  build_tools: {{ (_build_base + ['gcc', 'gcc-c++', 'make']) | tojson }}
  networking: {{ (_net_base + ['bind-utils', 'iputils', 'net-tools', 'nmap-ncat', 'openssh-clients', 'openssh-server']) | tojson }}
  compression: {{ (_compress_base + ['p7zip', 'p7zip-plugins', 'xz']) | tojson }}
  vcs_extras: {{ _vcs_base | tojson }}
  modern_cli: {{ (_modern_cli_base + ['fd-find']) | tojson }}
  security: [ca-certificates, gnupg2]
  acl: [acl]
  kvm: [libvirt, libvirt-client, libvirt-daemon, qemu-img, qemu-kvm, virt-install]

# ============================================================================
# ARCH PACKAGES (pacman/yay - different names, extra categories)
# ============================================================================
arch:
  core_utils: {{ (_core + ['vim', 'sed', 'glibc', 'glibc-locales', 'man-db']) | tojson }}
  monitoring: {{ (_monitoring_base + ['duf', 'ncdu']) | tojson }}
  shell_enhancements: {{ (_shell + ['zsh', 'zsh-autosuggestions', 'zsh-syntax-highlighting']) | tojson }}
  build_tools: {{ (_build_base + ['base-devel']) | tojson }}
  networking: {{ (_net_base + ['bind', 'iputils', 'net-tools', 'openbsd-netcat', 'openssh']) | tojson }}
  compression: {{ (_compress_base + ['p7zip', 'xz']) | tojson }}
  vcs_extras: {{ (_vcs_base + ['github-cli']) | tojson }}
  modern_cli: {{ (_modern_cli_base + ['fd']) | tojson }}
  security: [ca-certificates, gnupg]
  acl: [acl]
  kvm: [dnsmasq, edk2-ovmf, libvirt, qemu-desktop, virt-install, virt-manager]
  interpreters: [lua, perl, python, python-pip]
  modern_cli_extras: [bottom, delta, eza, hyperfine, procs, tealdeer, tokei, zoxide]
  fonts: [noto-fonts, noto-fonts-emoji, noto-fonts-cjk, ttf-fira-code, ttf-hac, ttf-jetbrains-mono, inter-font]
  theming: [arc-gtk-theme, kvantum, papirus-icon-theme]

# ============================================================================
# WINDOWS PACKAGES
# ============================================================================
windows:
  pwsh_modules: [PSReadLine, PowerShellGet, Microsoft.WinGet.Client, Microsoft.WinGet.CommandNotFound, powershell-yaml, PSFzf, PSWindowsUpdate, Terminal-Icons, Microsoft.PowerShell.Utility]
  choco: [chocolatey-compatibility.extension, chocolatey-core.extension, chocolatey-font-helpers.extension, cheatengine, colortool, Cygwin, dive, docker-cli, docker-compose, make,  vim, winbtrfs]
  winget:
    runtimes:
      ui_libraries: [Microsoft.UI.Xaml.2.7, Microsoft.UI.Xaml.2.8, Microsoft.VCLibs.Desktop.14]
      vcredist: [Microsoft.VCRedist.2008.x64, Microsoft.VCRedist.2008.x86, Microsoft.VCRedist.2010.x64, Microsoft.VCRedist.2010.x86, Microsoft.VCRedist.2012.x64, Microsoft.VCRedist.2012.x86, Microsoft.VCRedist.2013.x64, Microsoft.VCRedist.2013.x86, Microsoft.VCRedist.2015+.x64, Microsoft.VCRedist.2015+.x86]
      sdks: [Microsoft.WindowsADK, Microsoft.WindowsSDK.10.0.18362, Microsoft.NuGet, Microsoft.AppInstaller, Microsoft.AppInstallerFileBuilder]
      dotnet: [Microsoft.DotNet.DesktopRuntime.8, Microsoft.DotNet.DesktopRuntime.9, Microsoft.DotNet.Framework.DeveloperPack.4.6, Microsoft.DotNet.Runtime.8, Microsoft.DotNet.Runtime.9]
    system:
      sync_backup: [Syncthing.Syncthing, Martchus.syncthingtray]
      file_management: [7zip.7zip, WinSCP.WinSCP]
      compression: [Giorgiotani.Peazip]
      terminal: [Alacritty.Alacritty, Maximus5.ConEmu, Microsoft.WindowsTerminal]
      shell: [Git.Git, Microsoft.PowerShell, Starship.Starship]
      editor: [Obsidian.Obsidian]
      games: [Valve.Steam]
      utilities: [VB-Audio.Voicemeeter.Potato, CodeSector.TeraCopy, AntibodySoftware.WizTree, qBittorrent.qBittorrent, WerWolv.ImHex]
      media: [ImageMagick.ImageMagick, Ruben2776.PicView, Gyan.FFmpeg, HandBrake.HandBrake, SplitmediaLabs.XSplitBroadcaster]
      communication: [Vencord.Vesktop, hoppscotch.Hoppscotch]
      browser: [Google.Chrome]
      development: [GitHub.GitHubDesktop, GitHub.cli, Gitleaks.Gitleaks, JetBrains.IntelliJIDEA.Community, Microsoft.VisualStudio.BuildTools, Microsoft.VisualStudio.Community, Microsoft.VisualStudioCode, MSYS2.MSYS2]
      hardware: [ BitSum.ParkControl, BitSum.ProcessLasso, Guru3D.RTSS, Rem0o.FanControl, TechPowerUp.NVCleanstall, Wagnardsoft.DisplayDriverUninstaller]
      rgb_peripherals: [namazso.PawnIO, Nefarius.HidHide, Olivia.VIA, OpenRGB.OpenRGB, ViGEm.ViGEmBus]
      networking: [Apple.Bonjour, Insecure.Nmap, SSHFS-Win.SSHFS-Win, WinFsp.WinFsp, WiresharkFoundation.Wireshark]
      kubernetes: [Kubecolor.kubecolor]
      media_creative: [Audacity.Audacity, Cockos.REAPER, Inkscape.Inkscape, KDE.Krita, rocksdanister.LivelyWallpaper]
      ricing: [Rainmeter.Rainmeter]
    # 360 noscope - packages that choke on --scope machine flag
    noscope: [Microsoft.PowerShell, Starship.Starship, VB-Audio.Voicemeeter, Ruben2776.PicView, Olivia.VIA, Insecure.Nmap, Microsoft.UI.Xaml.2.7, Microsoft.UI.Xaml.2.8, Microsoft.AppInstallerFileBuilder, Microsoft.WindowsSDK.10.0.18362]
    userland:
      communication: [Telegram.TelegramDesktop]
      utilities: [Microsoft.PowerToys, Microsoft.Sysinternals.Autoruns, Microsoft.Sysinternals.ProcessExplorer, Rclone.Rclone, Rufus.Rufus, input-leap.input-leap]
      development: [DenoLand.Deno, direnv.direnv, Hashicorp.Terraform, Hashicorp.TerraformLanguageServer, nektos.act, waterlan.dos2unix, jqlang.jq]
      kubernetes: [Helm.Helm, Kubernetes.kubectl, stern.stern]
      hardware: [LibreHardwareMonitor.LibreHardwareMonitor]
      networking: [evsar3.sshfs-win-manager]
      gaming: [HeroicGamesLauncher.HeroicGamesLauncher, mtkennerly.ludusavi, Playnite.Playnite, SpecialK.SpecialK]
      media_creative: [yt-dlp.yt-dlp]
      desktop_customization: [AutoHotkey.AutoHotkey, File-New-Project.EarTrumpet]

# ============================================================================
# LANGUAGE-SPECIFIC PACKAGES
# ============================================================================
pip_base: [pip, setuptools, wheel, pipx, uv, pre-commit, ipython]

npm_global:
  - "@anthropic-ai/claude-code"
  - better-ccflare
  - pnpm
  - bun
  - tsx
  - "@angular/cli"
  - "@nestjs/cli"
  - "@vue/cli"
  - create-react-app
  - webpack
  - nodemon
  - pm2
  - serverless
  - cdk

brew: [atuin, carapace, pandoc, weasyprint, zoxide, dive]
