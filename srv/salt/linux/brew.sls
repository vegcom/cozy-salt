# Homebrew package installation
# Installs packages from provisioning/packages.sls brew list
# Requires: Homebrew already installed (via linux.homebrew state)
{% import_yaml "packages.sls" as packages %}
{% set managed_users = salt['pillar.get']('managed_users', []) %}
{% set brew_packages = packages.get('brew', []) %}
{% set service_user = managed_users[0] if managed_users else None %}
{% set homebrew_base = salt['pillar.get']('install_paths:homebrew:linux', '/home/linuxbrew/.linuxbrew') %}
{% if service_user and brew_packages %}
install_brew_packages:
  cmd.run:
    - name: {{ homebrew_base }}/bin/brew install {{ brew_packages | join(' ') }}
    - runas: {{ service_user }}
    - unless: ! test -x {{ homebrew_base }}/bin/bre
{% else %}
# No managed users or no brew packages defined
no_brew_packages:
  test.nop:
    - name: "No brew packages to install or no managed users"
{% endif %}
