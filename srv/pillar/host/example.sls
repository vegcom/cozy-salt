# Host-specific configuration override
# Copy this file and rename to match your hostname (e.g., myhost.sls)
# See CONTRIBUTING.md for details

workstation_role: workstation-full

locales:
  - en_US.UTF-8

host:
  capabilities:
    kvm: true
    k3s: true

k3s:
  role: server
  args: "--embedded-registry --disable-cloud-controller --debug"

# To enable chaotic_aur (already defined in dist/arch.sls as disabled):
pacman:
  repos:
    chaotic_aur:
      enabled: true
  # repos_extra adds NEW repos without replacing base repos
  repos_extra: {}

# Hosts file entries for network services
# Per-host overrides supported via pillar merge (e.g. localhost for self)
network:
  hosts:
    example:
      comment: example host
      ips:
        - 127.0.0.1
        - ::1
      names:
        - localhost
        - localhost.local
        - localhost.localdomain
