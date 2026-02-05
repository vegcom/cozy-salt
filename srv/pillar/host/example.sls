# Host-specific configuration override
# Copy this file and rename to match your hostname (e.g., myhost.sls)
# See CONTRIBUTING.md for details

workstation_role: workstation-full

locales:
  - en_US.UTF-8

host:
  capabilities:
    kvm: true

# To enable chaotic_aur (already defined in dist/arch.sls as disabled):
pacman:
  repos:
    chaotic_aur:
      enabled: true
  # repos_extra adds NEW repos without replacing base repos
  repos_extra: {}
