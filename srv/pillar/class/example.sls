# Example Hardware Class Pillar Override
# Copy and rename to match a hardware class grain (e.g., galileo.sls for Steam Deck)
# Applied to all systems in this class (via grains detection)

# Example: Override system locales for all systems in this class
# locales:
#   - en_US.UTF-8
#   - ja_JP.UTF-8

# Example: Configure repos for this hardware class
# pacman:
#   repos:
#     extra:
#       enabled: false
#     chaotic_aur:
#       enabled: true
#       server: "https://chaotic.cx/arch/aarch64"

# Example: Override workstation role for class
# workstation_role: 'workstation-full'

# Example: Hardware-specific display config
# display:
#   rotation:
#     enabled: true
#     angle: "right"
