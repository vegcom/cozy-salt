# Windows Package Roles - P2 Capability-Based Organization
# Defines which packages to install based on host role
#
# Usage in states: reference pillar.host_role to select package groups
# Example: {% set role = pillar.get('host_role', 'desktop') %}

# =============================================================================
# ROLE: minimal
# Use case: Minimal Windows installation (headless/server scenarios)
# Packages: ~15-20 (basic utilities only)
# =============================================================================
minimal:
  choco:
    - chocolatey-core.extension
    - chocolatey-compatibility.extension
  winget:
    - system_utilities:
      - 7zip.7zip
      - WinSCP.WinSCP
    - browsers:
      - Google.Chrome.EXE

# =============================================================================
# ROLE: base
# Use case: Standard Windows installation with shells and basic utilities
# Packages: ~40-50 (minimal + shells + system tools)
# =============================================================================
base:
  choco:
    - chocolatey-core.extension
    - chocolatey-compatibility.extension
    - chocolatey-font-helpers.extension
    - vim
    - FiraCode
    - nerd-fonts-FiraCode
    - nerd-fonts-Hack
    - colortool
  winget:
    - shells:
      - Starship.Starship
      - JanDeDobbeleer.OhMyPosh
      - Microsoft.WindowsTerminal
      - Microsoft.PowerShell.Preview
    - system_utilities:
      - 7zip.7zip
      - AntibodySoftware.WizTree
      - CodeSector.TeraCopy
      - Rufus.Rufus
      - WinSCP.WinSCP
      - Rclone.Rclone
      - Microsoft.PowerToys
    - browsers:
      - Google.Chrome.EXE
      - Microsoft.Edge

# =============================================================================
# ROLE: dev
# Use case: Developer workstation (base + development tools + runtimes)
# Packages: ~80-100 (base + dev_tools + kubernetes + runtimes)
# =============================================================================
dev:
  choco:
    - chocolatey-core.extension
    - chocolatey-compatibility.extension
    - chocolatey-font-helpers.extension
    - vim
    - FiraCode
    - nerd-fonts-FiraCode
    - nerd-fonts-Hack
    - Cygwin
    - colortool
    - make
    - rsync
  winget:
    - dev_tools:
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
    - kubernetes:
      - Kubernetes.kubectl
      - Kubernetes.minikube
      - Helm.Helm
      - Kubecolor.kubecolor
      - stern.stern
    - shells:
      - Starship.Starship
      - JanDeDobbeleer.OhMyPosh
      - Microsoft.WindowsTerminal
      - Microsoft.PowerShell.Preview
      - Microsoft.AIShell
    - system_utilities:
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
    - networking:
      - Tailscale.Tailscale
      - SSHFS-Win.SSHFS-Win
      - WinFsp.WinFsp
      - Insecure.Nmap
    - communication:
      - Microsoft.Teams
      - Obsidian.Obsidian
      - hoppscotch.Hoppscotch
    - browsers:
      - Google.Chrome.EXE
      - Microsoft.Edge
  winget_runtimes:
    - dotnet:
      - Microsoft.DotNet.Runtime.8
      - Microsoft.DotNet.Runtime.10
      - Microsoft.DotNet.DesktopRuntime.8
      - Microsoft.DotNet.DesktopRuntime.9
      - Microsoft.DotNet.DesktopRuntime.10
    - vcredist:
      - Microsoft.VCRedist.2015+.x86
      - Microsoft.VCRedist.2015+.x64

# =============================================================================
# ROLE: gaming
# Use case: Gaming-focused workstation (base + gaming + hardware + rgb)
# Packages: ~80-100 (base + gaming + hardware + rgb_peripherals + media)
# =============================================================================
gaming:
  choco:
    - chocolatey-core.extension
    - chocolatey-compatibility.extension
    - chocolatey-font-helpers.extension
    - vim
    - FiraCode
    - nerd-fonts-FiraCode
    - nerd-fonts-Hack
    - colortool
  winget:
    - shells:
      - Starship.Starship
      - JanDeDobbeleer.OhMyPosh
      - Microsoft.WindowsTerminal
      - Microsoft.PowerShell.Preview
    - system_utilities:
      - 7zip.7zip
      - AntibodySoftware.WizTree
      - CodeSector.TeraCopy
      - Microsoft.PowerToys
    - hardware:
      - REALiX.HWiNFO
      - LibreHardwareMonitor.LibreHardwareMonitor
      - Rem0o.FanControl
      - Guru3D.Afterburner
      - Guru3D.RTSS
      - BitSum.ProcessLasso
      - BitSum.ParkControl
      - TechPowerUp.NVCleanstall
    - rgb_peripherals:
      - OpenRGB.OpenRGB
      - OpenRGB.OpenRGBEffectsPlugin
      - OpenRGB.OpenRGBHardwareSyncPlugin
      - Ryochan7.DS4Windows
      - ViGEm.ViGEmBus
    - gaming:
      - Valve.Steam
      - Valve.SteamCMD
      - Playnite.Playnite
      - HeroicGamesLauncher.HeroicGamesLauncher
      - Beyond-All-Reason.Beyond-All-Reason
      - SpecialK.SpecialK
      - mtkennerly.ludusavi
    - media_creative:
      - Audacity.Audacity
      - Gyan.FFmpeg
      - yt-dlp.yt-dlp
    - browsers:
      - Google.Chrome.EXE
      - Microsoft.Edge

# =============================================================================
# ROLE: full
# Use case: Full installation with everything
# Packages: 174+ (all available packages)
# =============================================================================
full:
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
  winget:
    - dev_tools: all
    - kubernetes: all
    - shells: all
    - system_utilities: all
    - hardware: all
    - rgb_peripherals: all
    - networking: all
    - gaming: all
    - media_creative: all
    - communication: all
    - file_transfer: all
    - sync_backup: all
    - desktop_customization: all
    - browsers: all
  winget_runtimes:
    - dotnet: all
    - vcredist: all
    - ui_libraries: all
    - sdks: all

# =============================================================================
# PACKAGE COUNT ESTIMATES (after role-based filtering)
# =============================================================================
# minimal:  ~15-20 packages   (91% reduction from 174 packages)
# base:     ~40-50 packages   (71% reduction)
# dev:      ~80-100 packages  (42-54% reduction)
# gaming:   ~80-100 packages  (42-54% reduction)
# full:     ~174 packages     (0% reduction - all packages)
