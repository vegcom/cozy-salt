# Consolidated Package List for cozy-salt
# Source preference: Chocolatey > Winget (when package exists in both)
#
# Usage in Salt states:
#   {% import_yaml 'packages.sls' as packages %}
#   {% for pkg in packages.choco %}
#   {{ pkg }}:
#     chocolatey.installed
#   {% endfor %}

# =============================================================================
# LINUX PACKAGES (APT/DNF)
# =============================================================================
# Base packages for Debian/Ubuntu and RHEL/CentOS systems

apt:
  # --- Base Utilities ---
  - curl
  - wget
  - git
  - vim
  - htop
  - rsync
  - jq
  - tree
  - unzip

dnf:
  # --- Base Utilities (RHEL/CentOS equivalents) ---
  - curl
  - wget
  - git
  - vim-enhanced
  - htop
  - rsync
  - jq
  - tree
  - unzip

# =============================================================================
# CHOCOLATEY PACKAGES (Primary)
# =============================================================================
# These are installed via Chocolatey. When a package exists in both choco and
# winget, choco is preferred for better scripting support and consistency.

choco:
  # --- Package Managers & Meta ---
  - chocolatey-core.extension
  - chocolatey-compatibility.extension
  - chocolatey-font-helpers.extension

  # --- Container & DevOps ---
  - dive                          # Docker image explorer
  - docker-cli                    # Docker CLI (no daemon)
  - docker-compose                # Docker Compose v2

  # --- Editors (CHOCO PREFERRED - more config options) ---
  - vim                           # Vim - USE CHOCO, not winget vim.vim

  # --- Fonts ---
  - FiraCode
  - nerd-fonts-FiraCode
  - nerd-fonts-Hack

  # --- Shell & Terminal ---
  - Cygwin                        # USE CHOCO, not winget Cygwin.CygwinSetup
  - colortool                     # Windows console color schemes
  - rsync                         # File sync (via Cygwin)

  # --- Gaming/Modding ---
  - cheatengine                   # Memory scanner/debugger


# =============================================================================
# WINGET PACKAGES (Secondary)
# =============================================================================
# These are installed via Winget. Only packages NOT available or inferior in
# Chocolatey are listed here.

winget:
  # --- AI & ML ---
  - Anthropic.Claude              # Claude desktop app
  - Anthropic.ClaudeCode          # Claude Code CLI
  - ElementLabs.LMStudio          # Local LLM runner

  # --- Development: Languages & Runtimes ---
  - CoreyButler.NVMforWindows     # Node Version Manager
  - DenoLand.Deno                 # Deno runtime
  - GoLang.Go                     # Go language (deck only, add if needed)
  - Anaconda.Miniconda3           # Python via Miniconda
  - CondaForge.Miniforge3         # Python via Miniforge

  # --- Development: Tools ---
  - Git.Git                       # Git
  - GitHub.cli                    # GitHub CLI (gh)
  - Neovim.Neovim                 # Neovim
  - Microsoft.VisualStudioCode.Insiders  # VS Code Insiders
  - Microsoft.VisualStudioCode.CLI       # VS Code CLI
  - Hashicorp.Terraform           # Terraform
  - Hashicorp.TerraformLanguageServer    # Terraform LSP
  - nektos.act                    # Run GitHub Actions locally
  - jqlang.jq                     # JSON processor
  - junegunn.fzf                  # Fuzzy finder
  - ajeetdsouza.zoxide            # Smart cd (deck)
  - direnv.direnv                 # Directory-specific env vars
  - waterlan.dos2unix             # Line ending converter

  # --- Development: Kubernetes ---
  - Kubernetes.kubectl            # kubectl
  - Kubernetes.minikube           # Minikube
  - Helm.Helm                     # Helm package manager
  - Kubecolor.kubecolor           # Colorized kubectl
  - stern.stern                   # Multi-pod log tailing

  # --- Shell & Terminal ---
  - Starship.Starship             # Cross-shell prompt
  - JanDeDobbeleer.OhMyPosh       # PowerShell prompt
  - Microsoft.WindowsTerminal     # Windows Terminal
  - Microsoft.PowerShell.Preview  # PowerShell 7 Preview
  - Microsoft.AIShell             # AI Shell

  # --- System Utilities ---
  - 7zip.7zip                     # Archive manager
  - AntibodySoftware.WizTree      # Disk space analyzer
  - CodeSector.TeraCopy           # File copy utility
  - Rufus.Rufus                   # USB boot creator
  - Ventoy.Ventoy                 # Multi-boot USB
  - WinSCP.WinSCP                 # SFTP/SCP client
  - WinMerge.WinMerge             # File diff/merge (deck)
  - Rclone.Rclone                 # Cloud sync
  - Microsoft.Sysinternals.Autoruns      # Startup manager
  - Microsoft.Sysinternals.ProcessExplorer  # Process viewer
  - Microsoft.Sysinternals.ProcessMonitor   # Process monitor (deck)
  - Microsoft.PowerToys           # Windows power utilities

  # --- Hardware & Monitoring ---
  - REALiX.HWiNFO                 # Hardware info
  - LibreHardwareMonitor.LibreHardwareMonitor  # Hardware monitor
  - Rem0o.FanControl              # Fan control
  - Guru3D.Afterburner            # GPU overclocking
  - Guru3D.RTSS                   # Rivatuner (frame limiter)
  - BitSum.ProcessLasso           # Process priority manager
  - BitSum.ParkControl            # CPU parking control
  - TechPowerUp.NVCleanstall      # NVIDIA driver installer
  - Wagnardsoft.DisplayDriverUninstaller  # DDU

  # --- RGB & Peripherals ---
  - OpenRGB.OpenRGB               # RGB controller
  - OpenRGB.OpenRGBEffectsPlugin
  - OpenRGB.OpenRGBHardwareSyncPlugin
  - OpenRGB.OpenRGBVisualMapPlugin
  - Olivia.VIA                    # Keyboard configurator
  - Ryochan7.DS4Windows           # DualShock 4 support
  - ViGEm.ViGEmBus                # Virtual gamepad bus
  - Nefarius.HidHide              # HID device hider
  - namazso.PawnIO                # IO controller

  # --- Networking & Remote ---
  - Tailscale.Tailscale           # VPN mesh
  - SSHFS-Win.SSHFS-Win           # SSHFS for Windows
  - evsar3.sshfs-win-manager      # SSHFS GUI manager
  - WinFsp.WinFsp                 # Windows File System Proxy
  - Insecure.Nmap                 # Network scanner
  - WiresharkFoundation.Wireshark # Packet analyzer (deck)
  - Apple.Bonjour                 # mDNS/Bonjour

  # --- Gaming ---
  - Valve.Steam                   # Steam
  - Valve.SteamCMD                # Steam CLI
  - Playnite.Playnite             # Game launcher
  - HeroicGamesLauncher.HeroicGamesLauncher  # Epic/GOG launcher
  - Beyond-All-Reason.Beyond-All-Reason      # RTS game
  - SpecialK.SpecialK             # Game injector/fixer
  - mtkennerly.ludusavi           # Game save manager
  - MoonlightGameStreamingProject.Moonlight  # Game streaming (deck)
  - SteamGridDB.RomManager        # ROM manager (deck)

  # --- Media & Creative ---
  - Audacity.Audacity             # Audio editor
  - KDE.Krita                     # Digital painting
  - Gyan.FFmpeg                   # FFmpeg
  - yt-dlp.FFmpeg                 # FFmpeg (yt-dlp build)
  - yt-dlp.yt-dlp                 # Video downloader
  - Inkscape.Inkscape             # Vector graphics (deck)
  - rocksdanister.LivelyWallpaper # Animated wallpaper

  # --- Communication ---
  - Vencord.Vesktop               # Discord client
  - Proton.ProtonMailBridge       # ProtonMail
  - Microsoft.Teams               # Teams
  - Obsidian.Obsidian             # Note-taking
  - hoppscotch.Hoppscotch         # API testing

  # --- File Transfer ---
  - Transmission.Transmission     # Torrent client
  - DelugeTeam.Deluge             # Torrent client

  # --- Sync & Backup ---
  - Martchus.syncthingtray        # Syncthing tray
  - Microsoft.OneDrive            # OneDrive
  - restic.restic                 # Backup tool (deck)

  # --- Desktop Customization ---
  - RamenSoftware.Windhawk        # Windows customizer
  - AutoHotkey.AutoHotkey         # Automation
  - File-New-Project.EarTrumpet   # Volume mixer
  - Rainmeter.Rainmeter           # Desktop widgets (deck)
  - ModernFlyouts.ModernFlyouts   # Modern volume flyout (deck)
  - ArcadeRenegade.SidebarDiagnostics  # Sidebar diagnostics (deck)

  # --- Browsers ---
  - Google.Chrome.EXE             # Chrome
  - Microsoft.Edge                # Edge

  # --- Disk & Filesystem ---
  - GrafanaLabs.Alloy             # Grafana agent
  - maharmstone.btrfs             # Btrfs driver (deck)
  - maharmstone.Ntfs2btrfs        # NTFS to Btrfs converter (deck)
  - EFIBootEditor.EFIBootEditor   # EFI boot manager (deck)
  - CodingWondersSoftware.DISMTools.Stable  # DISM GUI (deck)
  - RaspberryPiFoundation.RaspberryPiImager  # Pi imager (deck)

  # --- Winget/System Management ---
  - Romanitho.Winget-AutoUpdate   # Auto-update via winget (deck)
  - KnifMelti.WAU-Settings-GUI    # WAU settings (deck)
  - lin-ycv.EverythingCmdPal      # Everything PowerToys (deck)
  - voidtools.Everything.Alpha    # Everything search (deck)


# =============================================================================
# WINGET: MICROSOFT STORE PACKAGES
# =============================================================================
# These require the msstore source in winget

winget_msstore:
  - XP99VR1BPSBQJ2                # (desktop) - Unknown store app
  - XP8K0HKJFRXGCK                # (deck) - Unknown store app (Oh My Posh?)


# =============================================================================
# WINGET: RUNTIMES & FRAMEWORKS
# =============================================================================
# Microsoft runtimes - typically auto-installed as dependencies

winget_runtimes:
  # --- .NET ---
  - Microsoft.DotNet.Runtime.8
  - Microsoft.DotNet.Runtime.10
  - Microsoft.DotNet.DesktopRuntime.3_1   # deck
  - Microsoft.DotNet.DesktopRuntime.5     # deck
  - Microsoft.DotNet.DesktopRuntime.6     # deck
  - Microsoft.DotNet.DesktopRuntime.7     # deck
  - Microsoft.DotNet.DesktopRuntime.8
  - Microsoft.DotNet.DesktopRuntime.9
  - Microsoft.DotNet.DesktopRuntime.10
  - Microsoft.DotNet.AspNetCore.9
  - Microsoft.DotNet.HostingBundle.8
  - Microsoft.DotNet.SDK.8                # deck
  - Microsoft.DotNet.Framework.DeveloperPack.4.6
  - Microsoft.DotNet.Framework.DeveloperPack_4   # deck

  # --- Visual C++ Redistributables ---
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

  # --- UI/UX Libraries ---
  - Microsoft.UI.Xaml.2.7
  - Microsoft.UI.Xaml.2.8
  - Microsoft.VCLibs.Desktop.14

  # --- SDKs & Tools ---
  - Microsoft.WindowsSDK.10.0.18362
  - Microsoft.WindowsADK
  - Microsoft.NuGet                       # deck
  - Microsoft.WebDeploy                   # deck
  - Microsoft.CLRTypesSQLServer.2019      # deck
  - Microsoft.GameInput                   # deck


# =============================================================================
# EXCLUDED FROM WINGET (use choco instead)
# =============================================================================
# These packages exist in winget but choco is preferred:
#
# - vim.vim              -> use choco:vim (better config)
# - Cygwin.CygwinSetup   -> use choco:Cygwin (includes packages)
# - OpenJS.NodeJS        -> use NVM (CoreyButler.NVMforWindows) instead
# - GnuWin32.Grep        -> use Cygwin or native tools
