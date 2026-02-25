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

bluetooth:
  enabled: true

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
