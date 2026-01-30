#!jinja|yaml
# Valve Galileo (Steam Deck) Hardware Class

docker_enabled: False

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
      user: false
  bluetooth:
    enabled: true
