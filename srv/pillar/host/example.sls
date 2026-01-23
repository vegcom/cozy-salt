# Host-specific configuration override
# Copy this file and rename to match your hostname (e.g., myhost.sls)
# See CONTRIBUTING.md for details

workstation_role: workstation-full

locales:
  - en_US.UTF-8

host:
  capabilities:
    kvm: true

pacman:
  repos:
    chaotic_aur:
      enabled: true
