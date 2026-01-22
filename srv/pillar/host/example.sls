# Example Host-Specific Pillar Override
# Copy and rename to match your minion_id (e.g., hostname.sls)
# Applied ONLY to the specific host that matches this filename

# Example: Set full workstation role (installs all packages)
# workstation_role: 'workstation-full'

# Example: Override system locales for this host
# locales:
#   - en_US.UTF-8
#   - de_DE.UTF-8

# Example: Disable Chaotic AUR on this host
# pacman:
#   repos:
#     chaotic_aur:
#       enabled: false

# Example: Override workstation role (options: workstation-minimal, workstation-base, workstation-developer, workstation-full)
# workstation_role: 'workstation-developer'

# Example: Enable KVM capability
# host:
#   capabilities:
#     kvm: true

# Example: Override user github config (email and name in .gitconfig.local)
# users:
#   vegcom:
#     github:
#       email: custom-email@example.com
#       name: Custom Name
#       tokens:
#         - ghp_customtoken123
#   eve:
#     github:
#       email: eve@example.com
#       name: Eve User
#       tokens:
#         - ghp_eve_token456
