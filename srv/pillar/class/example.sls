# Hardware class configuration override
# Copy this file and rename to match a hardware class (e.g., myclass.sls)
# Applied to all systems in this class via grains detection
# See CONTRIBUTING.md for details

workstation_role: workstation-full

locales:
  - en_US.UTF-8

pacman:
  repos:
    chaotic_aur:
      enabled: true
      server: "https://chaotic.cx/arch/aarch64"

display:
  rotation:
    enabled: true
    angle: "right"
