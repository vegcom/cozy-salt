# Homebrew package installation
# Installs packages from provisioning/packages.sls brew list
# Requires: Homebrew already installed (via linux.homebrew state)
# Runs as first managed user (Homebrew rejects root execution)

{% import_yaml "provisioning/packages.sls" as packages %}
{% set managed_users = salt['pillar.get']('managed_users', []) %}
{% set brew_packages = packages.get('brew', []) %}
{% set homebrew_user = managed_users[0] if managed_users else None %}
{% set homebrew_base = salt['pillar.get']('install_paths:homebrew:linux', '/home/linuxbrew/.linuxbrew') %}

{% if homebrew_user and brew_packages %}
install_brew_packages:
  cmd.run:
    - name: {{ homebrew_base }}/bin/brew install {{ brew_packages | join(' ') }}
    - runas: {{ homebrew_user }}
    - unless: ! test -x {{ homebrew_base }}/bin/brew
    - require:
      - cmd: homebrew_install

{% else %}
# No managed users or no brew packages defined
no_brew_packages:
  test.nop:
    - name: "No brew packages to install or no managed users"
{% endif %}
