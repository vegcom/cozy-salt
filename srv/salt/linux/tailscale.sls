# Linux Tailscale installation
# Installs tailscale via official install script, then configures via common.tailscale

tailscale_install:
  cmd.run:
    - name: curl -fsSL https://tailscale.com/install.sh | sh
    - unless: command -v tailscale

include:
  - common.tailscale
