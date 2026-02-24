#!jinja|yaml
# Valve Galileo (Steam Deck) Hardware Class

docker_enabled: True

steamdeck:
  autologin:
    user: deck

display:
  rotation:
    enabled: false
    angle: "right"
  touch_mapping:
    enabled: false

pipewire:
  quantum: {}

bluetooth:
  enabled: true

linux:
  login_manager:
    sddm:
      enabled: true
      theme: astronaut
      deploy_fonts: true
    autologin:
      user: deck
  bluetooth:
    enabled: true

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
