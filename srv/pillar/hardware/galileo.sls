#!jinja|yaml
# Valve Galileo (Steam Deck) Hardware Class

managed_users:
  - deck

host:
  capabilities:
    kvm: true
    k3s: true
    docker: true

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
      session: steam
      user: deck
  bluetooth:
    enabled: true

packages_absent:
  arch:
    nodeps: []
    normal: []

packages_extra:
  arch:
    kernel: []
    firmware: []
    deck_tools: [alsa-ucm-conf, amd-ucode, caps, dkms, noise-suppression-for-voice, sof-firmware, steamdeck-dkms, steamdeck-dsp, steamdeck-dsp-debug, upower, vpower, ludusavi-bin, hunspell, hunspell-fr, hunspell-en_gb, hunspell-en_us,hunspell-ja, cyme,xorg-xwininfo, xdotool, yad]

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
