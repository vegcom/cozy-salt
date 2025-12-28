# Linux Pillar Data
# Configuration values for Linux minions

# Provisioning paths
cozy:
  base_path: '/opt/cozy'

# SSH configuration
ssh:
  port: 2222  # Non-standard to avoid conflicts with Windows SSH on 22

# Shell customization
shell:
  prompt: starship
  theme_url: 'https://raw.githubusercontent.com/vegcom/Starship-Twilite/main/starship.toml'

# Package management
packages:
  manager: apt  # or yum, depending on distro
  auto_update: True
