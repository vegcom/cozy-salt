# Steam Deck (Valve Galileo) Hardware-Specific Configuration
# Only runs on detected Steam Deck hardware (DMI check)
#
# General Linux features moved to separate states:
# - SDDM, Autologin, Sleep Hooks → srv/salt/linux/config-login-manager.sls
# - Bluetooth → srv/salt/linux/config-bluetooth.sls
#
# This file reserved for Steam Deck-specific hardware configurations
# (currently none - hardware support provided via other states)

# Stub: No Steam Deck-specific configurations currently needed
# Bluetooth, SDDM, and display management handled by general states above
steamdeck_noop:
  test.nop:
    - name: Steam Deck hardware configuration (general features in config-login-manager.sls and config-bluetooth.sls)
