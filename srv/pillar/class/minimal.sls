#!jinja|yaml
# Minimal Hardware Class
# For constrained devices (Jetson, RPi, appliances) where we can't/shouldn't
# manage packages via apt. Just homebrew, ssh-keys, dotfiles.

workstation_role: minimal
docker_enabled: false
manage_users: false
