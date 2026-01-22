# Arch Linux Pacman Repository Configuration
# Manages /etc/pacman.conf and installs repo keyrings
# Only runs on Arch-based systems

{% if grains['os_family'] == 'Arch' %}

{% set pacman_repos = salt['pillar.get']('pacman:repos', {}) %}

# =============================================================================
# CHAOTIC AUR PREREQUISITES
# =============================================================================
# Install keyring and mirrorlist before adding Chaotic AUR repo
chaotic_keyring:
  pkg.installed:
    - name: chaotic-keyring
    - sources:
      - chaotic-keyring: https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst

chaotic_mirrorlist:
  pkg.installed:
    - name: chaotic-mirrorlist
    - sources:
      - chaotic-mirrorlist: https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst
    - require:
      - pkg: chaotic_keyring

# =============================================================================
# PACMAN.CONF REPOSITORY CONFIGURATION
# =============================================================================
# Deploys /etc/pacman.conf with repos from pillar
# Preserves existing settings outside of repo sections
pacman_conf:
  file.managed:
    - name: /etc/pacman.conf
    - mode: 644
    - user: root
    - group: root
    - contents: |
        # Arch Linux repository configuration
        # Managed by cozy-salt - DO NOT EDIT MANUALLY

        [options]
        #
        # Arch Linux repository mirrorlist
        # See ArchWiki (Mirrors) and Pacman/Tips#Enabling_parallel_downloads for more info on how to rate limit with aria2, wget and powerpill.
        #VerbosePkgLists
        Architecture = auto
        #CheckSpace
        #NoProgressBar
        ParallelDownloads = 5
        SigLevel = Required DatabaseOptional
        LocalFileSigLevel = Optional

        #
        # By default, pacman accepts packages signed by keys that it knows about.
        # SigLevel = Required DatabaseRequired

        {% for repo_name, repo_config in pacman_repos.items() %}
        {% if repo_config.get('enabled', false) %}

        [{{ repo_name }}]
        {% if repo_config.get('Server') %}
        Server = {{ repo_config.get('Server') }}
        {% endif %}
        {% if repo_config.get('server') %}
        Server = {{ repo_config.get('server') }}
        {% endif %}
        {% if repo_config.get('Include') %}
        Include = {{ repo_config.get('Include') }}
        {% endif %}
        {% if repo_config.get('SigLevel') %}
        SigLevel = {{ repo_config.get('SigLevel') }}
        {% endif %}

        {% endif %}
        {% endfor %}

# =============================================================================
# PACMAN DATABASE SYNC
# =============================================================================
# Refresh package database after repo changes
pacman_sync_after_config:
  cmd.run:
    - name: pacman -Sy
    - require:
      - file: pacman_conf
      - pkg: chaotic_mirrorlist

{% else %}

# Not an Arch-based system, skipping pacman configuration
pacman_config_skipped:
  test.nop:
    - name: Not an Arch-based system - skipping pacman config

{% endif %}
