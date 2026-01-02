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
# Port auto-detected: 22 for native Linux, 2222 for WSL (avoids Windows SSH conflict)
ssh:
  port: 22

# Shell customization
shell:
  prompt: starship
  # Optional: Custom starship.toml URL (defaults to starship's default config if not set)
  # Example: theme_url: 'https://raw.githubusercontent.com/your-user/your-theme/main/starship.toml'
  theme_url: ''

# Package management
packages:
  manager: apt  # or yum, depending on distro
  auto_update: True

# Node.js version management via nvm
nvm:
  default_version: 'lts/*'

# Workstation role-based package selection
# Options: workstation-minimal, workstation-base (default), workstation-developer
# - workstation-minimal: Core utilities + shell only
# - workstation-base: Core + monitoring + vcs + modern CLI + security (suitable for most users)
# - workstation-developer: Base + build tools + networking + KVM (for developers/testing)
workstation_role: 'workstation-base'

# Host capabilities (optional - enable specific features)
# Uncomment the capabilities needed for this host:
host:
  capabilities:
    # KVM virtualization (required for Dockur Windows testing)
    # Enabled automatically when 'kvm-host' role is set in grains
    kvm: {{ 'kvm-host' in salt['grains.get']('roles', []) }}
