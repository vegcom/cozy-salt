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
        ParallelDownloads = 5
        SigLevel = Required DatabaseOptional
        #XferCommand = /usr/local/bin/aria2-wrapper %u %o
        ILoveCandy
        VerbosePkgLists
        CheckSpace
        Color
        SigLevel = Required DatabaseRequired
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


pacman_sync_after_config:
  cmd.run:
    - name: |
      pacman -Syyu --noconfirm && \
      pacman -Scc --noconfirm
    - require:
      - file: pacman_conf

{% else %}

# Not an Arch-based system, skipping pacman configuration
pacman_config_skipped:
  test.nop:
    - name: Not an Arch-based system - skipping pacman config

{% endif %}
