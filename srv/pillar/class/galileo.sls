#!jinja|yaml
# Valve Galileo (Steam Deck) Hardware Class Defaults
# Applied to any system detected as: Manufacturer=Valve, Product Name=Galileo

---

docker_enabled: False

# =============================================================================
# PACMAN REPOSITORIES
# =============================================================================
# Repository configuration for Steam Deck
# Currently disabled - enable in host/ override if needed
pacman:
  repos:
    # Jupiter repository (SteamOS packages) - DISABLED by default
    # Uncomment in host/bokchoy.sls or class override to enable
    # jupiter-main:
    #   enabled: false
    #   server: "https://steamdeck-packages.steamos.cloud/archlinux-mirror/$repo/os/$arch"
    #   siglevel: "Never"
    
    # Chaotic-AUR mirror - DISABLED by default
    # Uncomment in host/bokchoy.sls to enable
    # chaotic-aur:
    #   enabled: false
    #   server: "https://chaotic.cx/arch/x86_64"
    #   key: "chaotic-aur"

---

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

---

# =============================================================================
# STEAM INPUT CONFIGURATION
# =============================================================================
# Steam Deck controller/input configuration
steam_input:
  # Steam controller config directory setup
  hardware_config:
    enabled: false  # Set to true in host/ to enable
    # Creates: ~/.config/Steam/hardware/steam_controller/
    # Symlinks: /dev/null → steam.input (disable Steam input detection)
    config_dir: "{{ pillar.get('user:name', 'deck') }}/.config/Steam/hardware/steam_controller"

---

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

---

# =============================================================================
# BLUETOOTH CONFIGURATION
# =============================================================================
# Bluetooth hardware setup (if present)
bluetooth:
  # Auto-enable on boot
  enabled: true
  # Additional settings managed in /etc/bluetooth/main.conf if needed

---

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
