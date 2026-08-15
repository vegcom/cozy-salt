{%- set service_user = salt['pillar.get']('aur_user', 'cozy-salt-svc') %}

# ============================================================================
# PACMAN DATABASE SYNC - Run before any package installation
# ============================================================================
pacman_sync:
  pacman.sync

# ============================================================================
# BOOTSTRAP: git + base-devel via pacman (required for yay bootstrap)
# These MUST use pacman directly since yay isn't installed yet
# ============================================================================
bootstrap_packages:
  pacman.installed:
    - pkgs:
      - git
      - base-devel
      - aria2
    - require:
      - pacman: pacman_sync
