# Arch Linux Pacman Repository Configuration
# Manages /etc/pacman.conf and installs repo keyrings
# Only runs on Arch-based systems

{% if grains['os_family'] == 'Arch' %}

{# Base repos from dist/arch.sls, extras from class/host append via pacman:repos_extra #}
{% set pacman_repos = salt['pillar.get']('pacman:repos', {}) %}
{% set pacman_repos_extra = salt['pillar.get']('pacman:repos_extra', {}) %}
{% do pacman_repos.update(pacman_repos_extra) %}
cozy_arch_downloader:
  file.managed:
    - name: /usr/local/bin/aria2-wrapper
    - source: salt://linux/files/usr-local-bin/aria2-wrapper
    - mode: "0775"
    - user: root
    - group: cozyusers

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
        SigLevel = Optional DatabaseOptional
        XferCommand = /usr/local/bin/aria2-wrapper %u %o
        ParallelDownloads = 8
        ILoveCandy
        VerbosePkgLists
        CheckSpace
        Color
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
        SigLevel = {{ repo_config.get('siglevel') }}
        {%- endif %}
        {%- endif %}
        {%- endfor %}
        {%- endif %}


pacman_init_key:
  cmd.run:
    - name: pacman-key --init
    - require:
      - file: pacman_conf

pacman_sync_key:
  cmd.run:
    - name: pacman-key --populate
    - require:
      - cmd: pacman_init_key

pacman_install_reflector:
  pkg.installed:
    - name: reflector
    - require:
      - cmd: pacman_sync_key

pacman_refresh_repo:
  cmd.run:
    - name: reflector --latest 5 --sort rate --save /etc/pacman.d/mirrorlist
    - require:
      - pkg: pacman_install_reflector

pacman_sync_repo:
  cmd.run:
    - name: pacman -Syy
    - require:
      - cmd: pacman_refresh_repo

pacman_update:
  cmd.run:
    - name: pacman -Su --noconfirm && pacman -Scc --noconfirm
    - require:
      - cmd: pacman_sync_repo



{% else %}

# Not an Arch-based system, skipping pacman configuration
pacman_config_skipped:
  test.nop:
    - name: Not an Arch-based system - skipping pacman config

{% endif %}
