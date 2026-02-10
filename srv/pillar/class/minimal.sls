#!jinja|yaml
# Minimal Hardware Class
# For constrained devices (Jetson, RPi, appliances) where we can't/shouldn't
# manage packages via apt. Just homebrew, ssh-keys, dotfiles, users.
#
# Does NOT manage:
#   - apt/pkg installs (locked repos)
#   - system paths
#   - docker (vendor-managed)

workstation_role: minimal
docker_enabled: false

# Users still managed, but minimal - just create user, ssh keys, dotfiles
# No uid/gid enforcement on vendor images
