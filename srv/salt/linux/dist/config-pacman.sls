# Arch Linux Pacman Repository Configuration
# Manages /etc/pacman.conf and installs repo keyrings
# Only runs on Arch-based systems

{% if grains['os_family'] == 'Arch' %}

{# Base repos from dist/arch.sls, extras from class/host append via pacman:repos_extra #}
{% set pacman_repos = salt['pillar.get']('pacman:repos', {}) %}
{% set pacman_repos_extra = salt['pillar.get']('pacman:repos_extra', {}) %}
{% do pacman_repos.update(pacman_repos_extra) %}

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

cozy_arch_profile:
  # TODO: wrap in such a way that `sudo function_name` will pass
  file.managed:
    - name: /etc/profile.d/99-cozy-arch.sh
    - mode: "0644"
    - user: root
    - group: root
    - contents: |
        #!/bin/bash
        pkgs_owned_files(){
          pacman -Qlq $1 | grep -v '/$' | xargs -r du -h | sort -h
        }
        alias pkgs_installed="pacman -Qq | fzf --preview 'pacman -Qil {}' --layout=reverse --bind 'enter:execute(pacman -Qil {} | less)'"
        alias pkgs_all="pacman -Slq | fzf --preview 'pacman -Si {}' --layout=reverse"
        alias pkg_unowned="(export LC_ALL=C.UTF-8; comm -13 <(pacman -Qlq | sed 's,/$,,' | sort) <(find /etc /usr /opt -path /usr/lib/modules -prune -o -print | sort))"

cozy_arch_downloader:
  file.managed:
    - name: /usr/local/bin/aria2-wrapper
    - source: salt://linux/files/usr-local-bin/aria2-wrapper
    - mode: "0775"
    - user: root
    - group: cozyusers

# =============================================================================
# PACMAN.CONF REPOSITORY CONFIGURATION
# =============================================================================
# Deploys /etc/pacman.conf with repos from pillar
# Preserves existing settings outside of repo sections
pacman_conf:
  file.managed:
    - name: /etc/pacman.conf
    - mode: "0644"
    - user: root
    - group: root
    - contents: |
        # Arch Linux repository configuration
        # Managed by cozy-salt - DO NOT EDIT MANUALLY

        [options]
        Architecture = auto
        HoldPkg = pacman glibc
        LocalFileSigLevel = Optional
        ParallelDownloads = 5
        SigLevel = Required DatabaseOptional
        #XferCommand = /usr/local/bin/aria2-wrapper %u %o
        ILoveCandy
        VerbosePkgLists
        CheckSpace
        Color

        #
        # By default, pacman accepts packages signed by keys that it knows about.
        # SigLevel = Required DatabaseRequired
        {%- if pacman_repos %}
        {%- for repo_name, repo_config in pacman_repos.items() %}
        {%- if repo_config.get('enabled', false) %}
        [{{ repo_name }}]
        {%- if repo_config.get('Server') %}
        Server = {{ repo_config.get('Server') }}
        {%- endif %}
        {%- if repo_config.get('server') %}
        Server = {{ repo_config.get('server') }}
        {%- endif %}
        {%- if repo_config.get('Include') %}
        Include = {{ repo_config.get('Include') }}
        {%- endif %}
        {%- if repo_config.get('include') %}
        Include = {{ repo_config.get('include') }}
        {%- endif %}
        {%- if repo_config.get('SigLevel') %}
        SigLevel = {{ repo_config.get('SigLevel') }}
        {%- endif %}
        {%- if repo_config.get('siglevel') %}
        SigLevel = {{ repo_config.get('liglevel') }}
        {%- endif %}
        {%- endif %}
        {%- endfor %}
        {%- endif %}

# =============================================================================
# PACMAN DATABASE SYNC
# =============================================================================
# Refresh package database after repo changes
pacman_sync_after_config:
  cmd.run:
    - name: pacman -Syy
    - require:
      - file: pacman_conf
      - pkg: chaotic_mirrorlist

{% else %}

# Not an Arch-based system, skipping pacman configuration
pacman_config_skipped:
  test.nop:
    - name: Not an Arch-based system - skipping pacman config

{% endif %}
