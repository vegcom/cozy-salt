#!jinja|yaml
# Valve Galileo (Steam Deck) Hardware Class

managed_users:
  - deck

docker_enabled: True

display:
  rotation:
    enabled: false
    angle: "right"
  touch_mapping:
    enabled: false

pipewire:
  quantum: {}

linux:
  login_manager:
    sddm:
      enabled: true
      theme: astronaut
      deploy_fonts: true
    autologin:
      session: plasma
      user: deck
  bluetooth:
    enabled: true

packages_absent:
  arch:
    nodeps: [linux-firmware]
    normal: []

packages_extra:
  arch:
    kernel: [linux-bazzite-bin]
    firmware:
      - linux-firmware-neptune
      - linux-firmware-neptune-bnx2x
      - linux-firmware-neptune-liquidio
      - linux-firmware-neptune-marvell
      - linux-firmware-neptune-mellanox
      - linux-firmware-neptune-nfp
      - linux-firmware-neptune-qcom
      - linux-firmware-neptune-qlogic
      - linux-firmware-neptune-whence
    deck_tools: [alsa-ucm-conf, amd-ucode, caps, dkms, fan-control, noise-suppression-for-voice, sof-firmware, steamdeck-dkms, steamdeck-dsp, steamdeck-dsp-debug, upower, vpower, ludusavi-bin, steam-boilr-gui, hunspell, hunspell-fr, hunspell-en_gb, hunspell-en_us,hunspell-ja]

pacman:
  repos:
    jupiter-main:
      enabled: true
      siglevel: Never
      server: https://steamdeck-packages.steamos.cloud/archlinux-mirror/$repo/os/$arch
    holo-main:
      enabled: true
      siglevel: Never
      server: https://steamdeck-packages.steamos.cloud/archlinux-mirror/$repo/os/$arch
