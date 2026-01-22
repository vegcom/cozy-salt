# Example Host-Specific Pillar Override
# Copy and rename to match your minion_id (e.g., hostname.sls)
# Applied ONLY to the specific host that matches this filename

# Example: Override system locales for this host
# locales:
#   - en_US.UTF-8
#   - de_DE.UTF-8

# Example: Disable Chaotic AUR on this host
# pacman:
#   repos:
#     chaotic_aur:
#       enabled: false

# Example: Override workstation role
# workstation_role: 'workstation-developer'

# Example: Enable KVM capability
# host:
#   capabilities:
#     kvm: true
