# cozy-salt TODO


## Seperation of duty

- [ ] Refactor config.sls
  - Presently config.sls is doing a lot of heavy lifting
  - Can be seperated by module/state

## Performance

- [ ] **Move package updates to orchestration**: pull `pacman -Su`, `pkg.uptodate`, `apt upgrade`, `dnf upgrade` etc out of highstate into `orch/update.sls`
  - Grep: `pkg.uptodate`, `pacman -Su`, `apt.*upgrade`, `dnf.*upgrade`
  - Separates "apply config" from "update packages" — highstate should be fast and idempotent

## Infra

- [ ] **cmd.run audit**: grep all states for `cmd.run.*(wget|curl)` and migrate to `file.managed` + `cmd.run` pattern ([k3s](./srv/salt/linux/k3s.sls) pattern as reference)
  - [ ] windows
    - [ ] Invoke-WebRequest
    - [ ] miniforge
    - [ ] nvm
    - [ ] windhawk
    - [ ] ... find more ...
  - [ ] linux
    - [ ] curl & wget
    - [ ] miniforge
    - [ ] nvm
    - [ ] rust
    - [ ] ... find more ...


## Feature

- [ ] Wire up template `srv/salt/_templates/alacritty.jinja` path depends on OS

- [ ] Below notes

```shell
# ✦ gamescope re-nice
# ✦➜ ref: https://github.com/ValveSoftware/gamescope/issues/107
# ✦➜ ref: https://wiki.archlinux.org/title/Gamescope
setcap 'CAP_SYS_NICE=eip' $(which gamescope)
```

```shell
# ✦ vulkan and native libs
# ✦➜ ref: https://www.reddit.com/r/linux_gaming/comments/15s4yz0/gamescope_fails_to_start_with_vulkan_error/
yay -S --noconfirm ccache sccache base-devel
# /etc/makepkg.conf
# BUILDENV=(!distcc color ccache check !sign)
yay -Qq|grep -Ei 'amdvlk|amdgpu'|yay -R --noconfirm||true
yay -S --noconfirm lib32-vulkan-radeon vulkan-radeon steam-native-runtime
```

```shell
# ✦ steam launch options ✦
# ✦➜ ref: https://wiki.archlinux.org/title/Steam/Troubleshooting#Steam_runtime
env STEAM_RUNTIME=0
 /usr/bin/steam
 -tenfoot 
 -fulldesktopres
 -gamepadui
 -dev
 -nointro
 -compat-force-slr off
 %U
```
 
```shell
# ✦ game launch options  ✦
# ✦➜ target:   kitty   ✦
env LD_PRELOAD="$LD_PRELOAD" GLFW_IM_MODULE="ibus"
 %command%
 --grab-keyboard=yes
 --single-instance=yes
 --start-as=fullscreen
```

```shell
gamescope --expose-wayland -- env LD_PRELOAD="$LD_PRELOAD" 
 %command%
```

```shell
# ✦ wip: trying to template ✦
# ✦➜ /home/deck/.local/share/applications/kitty.desktops
[Desktop Entry]
Categories=System;TerminalEmulator;
Comment=Fast, feature-rich, GPU based terminal
Exec= # ✦➜ <cmd>
GenericName=Terminal emulator
Icon=kitty
Name=kitty
NoDisplay=false
OnlyShowIn=KDE;
Path=
PrefersNonDefaultGPU=false
StartupNotify=true
Terminal=true
TerminalOptions=
TryExec=kitty
Type=Application
Version=1.0
X-KDE-SubstituteUID=false
X-KDE-Username=
X-TerminalArgAppId=--class
X-TerminalArgDir=--working-directory
X-TerminalArgExec=--
X-TerminalArgHold=--hold
X-TerminalArgTitle=--title
```


/etc/mkinitcpio.d/linux-bazzite.preset


fallback_config="/etc/mkinitcpio.conf"
fallback_image="/boot/initramfs-linux-bazzite-fallback.img"
fallback_uki="/boot/EFI/Linux/arch-linux-bazzite-fallback.efi" # <-- must be enforced
fallback_options="-S autodetect"



/etc/mkinitcpio.d/linux.preset
# mkinitcpio preset file for the 'linux' package

#ALL_config="/etc/mkinitcpio.conf"
ALL_kver="/boot/vmlinuz-linux"
#ALL_kerneldest="/boot/vmlinuz-linux"

PRESETS=('default')
#PRESETS=('default' 'fallback')

#default_config="/etc/mkinitcpio.conf"
#default_image="/boot/initramfs-linux.img"
default_uki="/boot/EFI/Linux/arch-linux.efi"  # <-- must be enforced
default_options="--splash /usr/share/systemd/bootctl/splash-arch.bmp"

#fallback_config="/etc/mkinitcpio.conf"
##fallback_image="/boot/initramfs-linux-fallback.img"
fallback_uki="/boot/EFI/Linux/arch-linux-fallback.efi"
#fallback_options="-S autodetect"


Review adding https://wiki.archlinux.org/title/Unofficial_user_repositories#ownstuff and https://wiki.archlinux.org/title/Unofficial_user_repositories#alucryd

Review managing https://wiki.archlinux.org/title/Makepkg


/etc/makepkg.conf:45
