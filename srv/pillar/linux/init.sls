#!jinja|yaml
# Linux Pillar Data
# Configuration values for Linux minions

# User configuration
# Auto-detected from login user (defaults to root in containers)
{% if salt['grains.get']('virtual', '') in ['docker', 'container', 'lxc'] %}
  {# In containers, default to root unless minion_id suggests otherwise #}
  {% set detected_user = 'root' %}
{% else %}
  {# On bare metal/VMs, try to detect actual user #}
  {% set detected_user = salt['environ.get']('SUDO_USER') or salt['environ.get']('LOGNAME') or 'root' %}
{% endif %}
user:
  name: {{ detected_user }}

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

# Node.js version management via nvm
nvm:
  default_version: 'lts'

# Host capabilities (optional - enable specific features)
# Uncomment the capabilities needed for this host:
host:
  capabilities:
    # KVM virtualization (required for Dockur Windows testing)
    # Enabled automatically when 'kvm-host' role is set in grains
    kvm: {{ 'kvm-host' in salt['grains.get']('roles', []) }}
