#!jinja|yaml
# Valve Galileo (Steam Deck) Hardware Class Defaults
# Applied to any system detected as: Manufacturer=Valve, Product Name=Galileo



#steamdeck:
#  autologin:
#    user: deck  # Replace with real username in host/


docker_enabled: False

# =============================================================================
# DISPLAY CONFIGURATION
# =============================================================================
# Display settings for Galileo/Steam Deck

# Touchscreen is rotated 90 degrees (landscape mode)
display:
  # Rotation settings (detect touchscreen device first)
  rotation:
    enabled: false  # Set to true in host/ to enable
    angle: "right"  # Options: left, right, inverted, normal
    # Device detection: looks for FTS3528 or similar touchscreen
    # Only applies if device is detected AND enabled is true

  # Xinput touch mapping (coordinates to rotated display)
  touch_mapping:
    enabled: false  # Set to true in host/ to enable
    # Device pattern: pointer:FTS3528 or similar
    # Automatically detected from xinput list output


# =============================================================================
# AUDIO/PIPEWIRE CONFIGURATION
# =============================================================================
# PipeWire audio tuning for Steam Deck
pipewire:
  # PipeWire quantum size (buffer size for low latency)
  quantum:
    # Default on Steam Deck: 512
    # Set in host/ to override
    # min_quantum: 256
    # max_quantum: 2048

  # Config location (don't manage here - user edits ~/.config/pipewire/pipewire.conf)
  # Example: echo "default.clock.min-quantum = 256" > ~/.config/pipewire/pipewire.conf


# =============================================================================
# BLUETOOTH CONFIGURATION
# =============================================================================
# Bluetooth hardware setup (if present)
bluetooth:
  # Auto-enable on boot
  enabled: true
  # Additional settings managed in /etc/bluetooth/main.conf if needed


# =============================================================================
# YOINK: Future Work
# =============================================================================
# Uncomment and configure as needed:

# # Atuin shell history sync (enable in host/ override)
# shell:
#   atuin:
#     enabled: false
#     sync: false  # Disable cloud sync for privacy

# # Carapace shell completion (enable in host/ override)
# shell:
#   carapace:
#     enabled: false

# # Rbenv (Ruby version manager) - may conflict with system ruby
# ruby:
#   rbenv:
#     enabled: false
#     versions: []  # Install specific Ruby versions if enabled


# pacman:
#   repos:
#     kde-unstable:
#       enabled: true
#       Include: /etc/pacman.d/mirrorlist

#     core:
#       enabled: true
#       Include: /etc/pacman.d/mirrorlist

#     extra:
#       enabled: true
#       Include: /etc/pacman.d/mirrorlist

#     multilib:
#       enabled: true
#       Include: /etc/pacman.d/mirrorlist

# =============================================================================
# Steam Deck: Login Manager (SDDM)
# =============================================================================
linux:
  login_manager:
    sddm:
      enabled: true
      theme: astronaut
      deploy_fonts: true
    autologin:
      user: false               # Set to 'deck' or username to enable autologin

  # =============================================================================
  # Steam Deck: Bluetooth
  # =============================================================================
  bluetooth:
    enabled: true
