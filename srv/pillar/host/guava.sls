#!jinja|yaml
# Host Pillar: guava (Steam Deck - maple-trees)
# Overrides class/galileo.sls defaults for this specific machine

---

# =============================================================================
# DISPLAY CONFIGURATION (guava specific overrides)
# =============================================================================
display:
  rotation:
    enabled: false  # Set to true to enable xrandr rotation
    angle: "right"  # 90-degree rotation for tablet mode
  
  touch_mapping:
    enabled: false  # Set to true to map touchscreen to rotated display

---

# =============================================================================
# STEAM INPUT CONFIGURATION
# =============================================================================
steam_input:
  hardware_config:
    enabled: false  # Set to true to disable Steam input auto-detection

---

# =============================================================================
# BLUETOOTH CONFIGURATION
# =============================================================================
bluetooth:
  enabled: true  # Auto-enable Bluetooth on boot

---

# =============================================================================
# PACMAN REPOSITORIES (guava specific)
# =============================================================================
# All disabled by default - uncomment to enable
pacman:
  repos: {}
  # Uncomment below to enable Jupiter or Chaotic repositories
  
  # jupiter:
  #   enabled: true
  #   server: "https://steamdeck-packages.steamos.cloud/archlinux-mirror/$repo/os/$arch"
  #   siglevel: "Never"
  
  # chaotic_aur:
  #   enabled: false
  #   server: "https://chaotic.cx/arch/x86_64"

---

# =============================================================================
# LOCALE & TIMEZONE
# =============================================================================
# Inherit from linux/init.sls unless overriding here

---

# =============================================================================
# NOTE: Future customizations
# =============================================================================
# - Add Atuin config if fixing shell history
# - Add specific nvm/miniforge paths if needed
# - Add custom user groups/sudo access if needed
