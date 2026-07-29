#!jinja|yaml
# Package Definitions for cozy-salt
# See docs/package-management.md for usage and architecture
#
# Structure: distro_aliases, package_metadata, per-distro packages, windows, pip/npm/brew
# Capability groups: core_utils, shell_enhancements, monitoring, compression, vcs_extras,
#                    modern_cli, security, acl, build_tools, networking, kvm
# Arch-only: modern_cli_extras, interpreters, fonts, theming, gui

# ============================================================================
# SHARED PACKAGE LISTS (DRY - referenced by distro sections below)
# ============================================================================
{%- set _core = ['curl', 'git', 'jq', 'rsync', 'tree', 'unzip', 'wget', 'aria2', 'dkms', 'inotify-tools'] %}
{%- set _monitoring_base = ['htop', 'lsof', 'ltrace', 'strace', 'sysstat'] %}
{%- set _shell = ['bash-completion', 'screen', 'tmux', 'shellcheck', 'zsh'] %}
{%- set _shell_rhel = (_shell | reject('equalto', 'shellcheck') | list) + ['ShellCheck'] %}
{%- set _build_base = ['autoconf', 'automake', 'cmake'] %}
{%- set _net_base = ['nmap', 'socat', 'tcpdump', 'traceroute'] %}
{%- set _compress_base = ['bzip2', 'zip'] %}
{%- set _vcs_base = ['git-lfs', 'tig'] %}
{%- set _modern_cli_base = ['bat', 'ripgrep'] %}

# ============================================================================
# APT-BASED (Debian/Ubuntu) - single definition, both reference it
# ============================================================================
{%- set _apt = {
    'core_utils': _core + ['vim'],
    'monitoring': _monitoring_base + ['duf', 'ncdu'],
    'shell_enhancements': _shell,
    'build_tools': _build_base + ['build-essential', 'pkg-config'],
    'networking': _net_base + ['avahi-daemon', 'bind9-dnsutils', 'etcd-client', 'iputils-ping', 'net-tools', 'netcat-openbsd', 'openssh-client', 'openssh-server', 'wsdd-server', 'libnss-mdns'],
    'compression': _compress_base + ['7zip', 'xz-utils'],
    'vcs_extras': _vcs_base + ['gh'],
    'modern_cli': _modern_cli_base + ['fd-find'],
    'security': ['ca-certificates', 'systemd-journal-remote'],
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
    container_runtime: [docker-ce, podman, containerd]
    database_mysql: [mysql, mariadb, percona-server]
    firewall: [ufw, firewalld, iptables-persistent]
    java_17_jdk: [openjdk-17-jdk, java-17-openjdk-devel, jdk17-openjdk]
    java_21_jdk: [openjdk-21-jdk, java-21-openjdk-devel, jdk21-openjdk]
    mta: [postfix, sendmail, exim4]
    netcat_variants: [netcat-openbsd, nmap-ncat, openbsd-netcat, gnu-netcat]

  optional:
    dev_extras: [gh, git-lfs, tig, lazygit]
    modern_cli_tools: [bat, fd, ripgrep, duf, ncdu, eza, zoxide]
    shell_extras: [zsh-autosuggestions, zsh-syntax-highlighting, starship]

  required:
    build: [gcc, make]
    core: [curl, git, openssh, ca-certificates]
    network: [ping, traceroute, dig, avahi]

  exclude:
    arch: [cpu-checker, build-essential, openssh-client, openssh-server, vim-enhanced, fd-find, gnupg2]
    debian: [github-cli]
    rhel: [duf, ncdu]

  provides:
    avahi: {ubuntu: avahi-daemon, debian: avahi-daemon, rhel: avahi, arch: avahi}
    build_essentials: {ubuntu: build-essential, debian: build-essential, rhel: ['gcc', 'gcc-c++', 'make', 'autoconf', 'automake'], arch: base-devel}
    compression_7z: {ubuntu: 7zip, debian: 7zip, rhel: 7zip, arch: p7zip}
    dns_utils: {ubuntu: bind9-dnsutils, debian: bind9-dnsutils, rhel: bind-utils, arch: bind}
    etcd_client: {ubuntu: etcd-client, debian: etcd-client, rhel: etcd-client, arch: etcd-bin}
    github_cli: {ubuntu: gh, debian: gh, rhel: gh, arch: github-cli}
    netcat: {ubuntu: netcat-openbsd, debian: netcat-openbsd, rhel: nmap-ncat, arch: openbsd-netcat}
    shellcheck: {ubuntu: shellcheck, debian: shellcheck, rhel: ShellCheck, arch: shellcheck}
    ssh_client: {ubuntu: openssh-client, debian: openssh-client, rhel: openssh-clients, arch: openssh}
    ssh_server: {ubuntu: openssh-server, debian: openssh-server, rhel: openssh-server, arch: openssh}
    vim: {ubuntu: vim, debian: vim, rhel: vim-enhanced, arch: vim}
    wsdd-server: {ubuntu: wsdd-server, rhel: wsdd-server, arch: wsdd}

# ============================================================================
# DEBIAN/UBUNTU PACKAGES (apt-based, identical)
# ============================================================================
debian: {{ _apt | tojson }}
ubuntu: {{ _apt | tojson }}

# ============================================================================
# RHEL PACKAGES (dnf/yum - different pkg names, no duf/ncdu in base repos)
# ============================================================================
rhel:
  acl: [acl]
  build_tools: {{ (_build_base + ['gcc', 'gcc-c++', 'make']) | tojson }}
  compression: {{ (_compress_base + ['7zip', 'xz']) | tojson }}
  core_utils: {{ (_core + ['vim-enhanced']) | tojson }}
  kvm: [libvirt, libvirt-client, libvirt-daemon, qemu-img, qemu-kvm, virt-install]
  modern_cli: {{ (_modern_cli_base + ['fd-find']) | tojson }}
  monitoring: {{ _monitoring_base | tojson }}
  networking: {{ (_net_base + ['avahi', 'bind-utils', 'etcd-client', 'iputils', 'net-tools', 'nmap-ncat', 'openssh-clients', 'openssh-server', 'wsdd-server', 'nss-mdns']) | tojson }}
  security: [ca-certificates, gnupg2, systemd-journal-remote]
  shell_enhancements: {{ _shell_rhel | tojson }}
  vcs_extras: {{ _vcs_base | tojson }}

# ============================================================================
# ARCH PACKAGES (pacman/yay - different names, extra categories)
# ============================================================================
arch:
  build_tools: {{ (_build_base + ['base-devel']) | tojson }}
  compression: {{ (_compress_base + ['p7zip', 'xz']) | tojson }}
  core_utils: {{ (_core + ['vim', 'sed', 'glibc', 'glibc-locales', 'man-db', 'python-pyinotify']) | tojson }}
  modern_cli: {{ (_modern_cli_base + ['fd']) | tojson }}
  monitoring: {{ (_monitoring_base + ['duf', 'ncdu']) | tojson }}
  networking: {{ (_net_base + ['avahi', 'bind', 'etcd-bin', 'iputils', 'net-tools', 'openbsd-netcat', 'openssh', 'wsdd', 'nss-mdns']) | tojson }}
  shell_enhancements: {{ (_shell + ['zsh', 'zsh-autosuggestions', 'zsh-syntax-highlighting']) | tojson }}
  vcs_extras: {{ (_vcs_base + ['github-cli']) | tojson }}
  acl: [acl]
  container: [docker, docker-buildx]
  debugging: [downgrade]
  fonts: [noto-fonts, noto-fonts-emoji, noto-fonts-cjk, ttf-fira-code, ttf-hack, ttf-jetbrains-mono, inter-font]
  gaming: [waydroid-launcher-git, protontricks, steam, gamescope,  lib32-gamescope-plus, mangohud, moonlight-qt, protonup-qt-bin]
  gui: [plasma-meta, hyprland, plasma-keyboard]
  interpreters: [lua, perl, python, python-pip]
  kernel: []
  kvm: [dnsmasq, edk2-ovmf, libvirt, qemu-desktop, virt-install, virt-manager]
  modern_cli_extras: [bottom, eza, hyperfine, procs, tealdeer, tokei, zoxide]
  security: [ca-certificates, gnupg]
  sound: [pipewire, pipewire-alsa, pipewire-pulse, wireplumber]
  sync_backup: [syncthing, ludusavi]
  theming: [kvantum]

# ============================================================================
# WINDOWS PACKAGES
# ============================================================================
windows:

  pwsh_modules: [PowerShellGet, Microsoft.PowerShell.PSResourceGet, PackageManagement, PSReadLine, Microsoft.WinGet.Client, Microsoft.WinGet.CommandNotFound, powershell-yaml, PSFzf, PSWindowsUpdate, Terminal-Icons, BurntToast]

  choco: [chocolatey-compatibility.extension, chocolatey-core.extension, chocolatey-font-helpers.extension, cheatengine, colortool, Cygwin, dive, docker-cli, docker-compose, make,  vim, winbtrfs, ext2fsd, jq, tor, ipfs-mount]

  winget:

    runtimes:
      dotnet: [Microsoft.DotNet.DesktopRuntime.8, Microsoft.DotNet.DesktopRuntime.9, Microsoft.DotNet.Framework.DeveloperPack.4.6, Microsoft.DotNet.Runtime.8]
      java: [Oracle.JavaRuntimeEnvironment, Oracle.JDK.26]
      sdks: [Microsoft.WindowsADK, Microsoft.NuGet]
      ui_libraries: []
      vcredist: [Microsoft.VCRedist.2008.x64, Microsoft.VCRedist.2008.x86, Microsoft.VCRedist.2010.x64, Microsoft.VCRedist.2010.x86, Microsoft.VCRedist.2012.x64, Microsoft.VCRedist.2012.x86, Microsoft.VCRedist.2013.x64, Microsoft.VCRedist.2013.x86, Microsoft.VCRedist.2015+.x64, Microsoft.VCRedist.2015+.x86]

    system:
      browser: [Google.Chrome]
      communication: []
      compression: [Giorgiotani.Peazip]
      development: [GitHub.GitHubDesktop, GitHub.cli, Gitleaks.Gitleaks, JetBrains.IntelliJIDEA.Community, Microsoft.VisualStudio.BuildTools, Microsoft.VisualStudio.Community, Microsoft.VisualStudioCode, Microsoft.VisualStudioCode.CLI, Microsoft.VisualStudioCode.Insiders, Microsoft.VisualStudioCode.Insiders.CLI, MSYS2.MSYS2, NSIS.NSIS, Kitware.CMake, Anthropic.ClaudeCode, BurntSushi.ripgrep.MSVC, hoppscotch.Hoppscotch]
      editor: [Obsidian.Obsidian]
      file_management: [7zip.7zip, WinSCP.WinSCP, voidtools.Everything.Cli, voidtools.Everything]
      games: [Valve.Steam]
      hardware: [TechPowerUp.NVCleanstall, Wagnardsoft.DisplayDriverUninstaller, tuna-f1sh.cyme]
      kubernetes: [Kubecolor.kubecolor, Freelensapp.Freelens]
      media: [ImageMagick.ImageMagick, Ruben2776.PicView, Gyan.FFmpeg, yang991178.fluent-reader]
      networking: [Apple.Bonjour, WiresharkFoundation.Wireshark, Tailscale.Tailscale]
      ricing: [Rainmeter.Rainmeter]
      shell: [Git.Git]
      sync_backup: [Syncthing.Syncthing, Martchus.syncthingtray]
      terminal: [Alacritty.Alacritty, Maximus5.ConEmu, Microsoft.WindowsTerminal]
      utilities: [CodeSector.TeraCopy, AntibodySoftware.WizTree, qBittorrent.qBittorrent, WerWolv.ImHex]

    userland:
      communication: [Telegram.TelegramDesktop]
      desktop_customization: [AutoHotkey.AutoHotkey, File-New-Project.EarTrumpet]
      development: [DenoLand.Deno, direnv.direnv, Hashicorp.Terraform, Hashicorp.TerraformLanguageServer, nektos.act, waterlan.dos2unix]
      gaming: [HeroicGamesLauncher.HeroicGamesLauncher, mtkennerly.ludusavi, Playnite.Playnite, SpecialK.SpecialK]
      kubernetes: [Helm.Helm, Kubernetes.kubectl, stern.stern]
      media_creative: [yt-dlp.yt-dlp]
      networking: [evsar3.sshfs-win-manager]
      utilities: [Microsoft.PowerToys, davidegiacometti.VisualStudioForCmdPal, nickknissen.TailscaleCommandPalette,  Rclone.Rclone, Rufus.Rufus]
      ricing: [MicaForEveryone.MicaForEveryone]

    gated:
      voicemeter: [VB-Audio.Voicemeeter.Potato]
      xsplit: []
      ghelper: [seerge.g-helper]
      controllers: [Rem0o.FanControl, OpenRGB.OpenRGB]
      bitsum: [BitSum.ParkControl, BitSum.ProcessLasso]
      rtss: [Guru3D.RTSS]
      hw_monitor: [REALiX.HWiNFO, TechPowerUp.GPU-Z]
      peripherals_ctrl: [namazso.PawnIO, Nefarius.HidHide, ViGEm.ViGEmBus]
      media_stream: []
      media_video: []
      media_audio: [Audacity.Audacity, Cockos.REAPER]
      media_imaeg: [Inkscape.Inkscape, KDE.Krita]

    noscope:
      communication: [Vencord.Vesktop]
      terminal: [Microsoft.PowerShell, Starship.Starship]
      utilities: [Microsoft.Sysinternals.Suite, TRGamer-tech.FluentTaskScheduler]
      development: [Microsoft.VCLibs.Desktop.14, NASM.NASM]
      media: [Ruben2776.PicView, HandBrake.HandBrake]
      via: [Olivia.VIA]
      ui_libraries: [Microsoft.UI.Xaml.2.7, Microsoft.UI.Xaml.2.8]
      vcredist: [Microsoft.DotNet.Runtime.9, Microsoft.DotNet.DesktopRuntime.10]
      networking: [Insecure.Nmap]
      xsplit: [SplitmediaLabs.XSplitBroadcaster]

# ============================================================================
# LANGUAGE-SPECIFIC PACKAGES
# ============================================================================

pip_base: [pip, setuptools, wheel, pipx, uv, pre-commit, ipython, pytest, mypy, ruff, pipenv, pixi, poetry, gitpython, djlint]

npm_global:
  - "@angular/cli"
  - "@nestjs/cli"
  - "@vue/cli"
  - better-ccflare
  - bun
  - cdk
  - create-react-app
  - nodemon
  - pm2
  - pnpm
  - serverless
  - tsx
  - webpack

brew:
  formula: [atuin, carapace, pandoc, weasyprint, zoxide, dive, starship, direnv, claude-code, kubecolor, fzf, xdotool, cyme, ripgrep]
  cask: []
