# Host-specific configuration override
# Copy this file and rename to match your hostname (e.g., myhost.sls)
# See CONTRIBUTING.md for details

# workstation_role: workstation-full

# locales:
#   - en_US.UTF-8

# host:
#   capabilities:
#     kvm: true
#     k3s: true
#     tailscale: false  # default true — disable only if not using tailscale

k3s:
  # srv/salt/linux/k3s.sls
  # role: server # (server,loadbalancer,agent)
  # kwargs: "--disable=servicelb --disable=traefik --disable-cloud-controller --data-dir=/storage/k3s/"

# mine_functions:
#   k3s_kubeconfig:
#     mine_function: file.read
#     path: /etc/rancher/k3s/k3s.yaml
#   k3s_node_token:
#     mine_function: file.read
#     path: /storage/k3s/server/node-token

# To enable chaotic_aur (already defined in dist/arch.sls as disabled):
# pacman:
#   repos:
#     chaotic_aur:
#       enabled: true
#   # repos_extra adds NEW repos without replacing base repos
#   repos_extra: {}

# Hosts file entries for network services
# Per-host overrides supported via pillar merge (e.g. localhost for self)
# network:
#   hosts:
#     example:
#       comment: example host
#       ips:
#         - 127.0.0.1
#         - ::1
#       names:
#         - localhost
#         - localhost.local
#         - localhost.localdomain

# Macvlan shim for Docker frontend network
# macvlan_shim:
#   parent: eth0
#   shim_name: frontend-shim
#   shim_ip: 10.0.0.254
#   routes:
#     - 10.0.0.23
#     - 10.0.0.45
