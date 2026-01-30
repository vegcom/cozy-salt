# Hardware class configuration override
# Copy this file and rename to match a hardware class (e.g., myclass.sls)
# Applied to all systems in this class via grains detection
# See CONTRIBUTING.md for details

workstation_role: workstation-full

locales:
  - en_US.UTF-8

# pacman:repos_extra appends to base repos (dist/arch.sls)
# Use repos_extra to ADD new repos, not replace existing
pacman:
  repos_extra:
    my_custom_repo:
      enabled: true
      server: "https://example.com/arch/$arch"

display:
  rotation:
    enabled: true
    angle: "right"
