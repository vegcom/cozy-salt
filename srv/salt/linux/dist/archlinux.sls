# Arch Linux package installation (Role-Aware)
# Packages organized by capability/purpose using yay (AUR helper)
# Role-based selection via workstation_role pillar:
#   - workstation-minimal: core + shell
#   - workstation-base: minimal + monitoring, compression, vcs, modern-cli, security, acl
#   - workstation-developer: base + build tools, networking, kvm
#   - workstation-full (default): all capabilities + interpreters, shells, CLI extras, fonts, theming, gui
# See provisioning/packages.sls for full package definitions
# See srv/pillar/arch/init.sls for capability_meta and aur_user

{%- import_yaml 'packages.sls' as packages %}
{%- set os_name = 'arch' %}
{%- set workstation_role = salt['pillar.get']('workstation_role', 'workstation-full') %}
{%- set capability_meta = salt['pillar.get']('capability_meta', {}) %}
{%- set service_user = salt['pillar.get']('aur_user', 'cozy-salt-svc') %}
{%- set github_token = salt['pillar.get']('github:access_token', '') %}

# Get role capabilities from pillar (centralized in srv/pillar/linux/init.sls)
{%- set role_capabilities = salt['pillar.get']('linux', {}) %}
{%- set capabilities = role_capabilities.get(workstation_role, role_capabilities.get('workstation-full', [])) %}

{%- if grains['os_family'] == 'Arch' %}
include:
  - linux.gpu

# ============================================================================
# Arch Linux Pacman Repository Configuration
# ----------------------------------------------------------------------------
# Manages /etc/pacman.conf and installs repo keyrings
# Only runs on Arch-based systems
# ============================================================================

{# Base repos from dist/arch.sls, extras from class/host append via pacman:repos_extra #}
{%- set pacman_repos = salt['pillar.get']('pacman:repos', {}) %}
{%- set pacman_repos_extra = salt['pillar.get']('pacman:repos_extra', {}) %}
{%- do pacman_repos.update(pacman_repos_extra) %}
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
        #XferCommand = /usr/local/bin/aria2-wrapper %u %o
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

# ============================================================================
# YAY BOOTSTRAP: Clone and build yay-bin from AUR
# Runs as aur_user since makepkg cannot run as root
# ============================================================================
yay_build_dir:
  file.directory:
    - name: /home/{{ service_user }}/.cache/yay-bootstrap
    - user: {{ service_user }}
    - group: {{ service_user }}
    - mode: "0755"
    - makedirs: True
    - require:
      - pacman: bootstrap_packages
      # - user: {{ service_user }}_user

yay_clone:
  git.latest:
    - name: https://aur.archlinux.org/yay-bin.git
    - target: /home/{{ service_user }}/.cache/yay-bootstrap/yay-bin
    - user: {{ service_user }}
    - force_clone: True
    - require:
      - file: yay_build_dir
    - unless: which yay

yay_install:
  cmd.run:
    - name: makepkg -si --noconfirm
    - cwd: /home/{{ service_user }}/.cache/yay-bootstrap/yay-bin
    - runas: {{ service_user }}
    - env:
      - HOME: /home/{{ service_user }}
      - USER: {{ service_user }}
      - LANG: C.UTF-8
      - PATH: /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
    - require:
      - git: yay_clone
    - unless: which yay

# ============================================================================
# FOUNDATION: core_utils via yay (runs first, others depend on this)
# ============================================================================
{%- if 'core_utils' in capabilities and 'core_utils' in packages.get(os_name, {}) %}
{%- set core_meta = capability_meta.get('core_utils', {'state_name': 'core_utils_packages'}) %}
{{ core_meta.state_name }}:
  yay.installed:
    - pkgs: {{ packages[os_name].core_utils | tojson }}
    - runas: {{ service_user }}
    - require:
      - cmd: yay_install
{%- endif %}

# ============================================================================
# CAPABILITIES: Loop through all non-foundation capabilities via yay
# ============================================================================
{%- for cap_key, cap_meta in capability_meta.items() %}
{# Skip foundation (handled above) and capabilities not in current role #}
{%- if not cap_meta.get('is_foundation', false) and cap_key in capabilities %}
{# Check packages exist for this distro and list is non-empty #}
{%- if packages.get(os_name, {}).get(cap_key) %}
{# Check pillar gate if defined (e.g., kvm needs host:capabilities:kvm) #}
{%- set pillar_gate = cap_meta.get('pillar_gate') %}
{%- if not pillar_gate or salt['pillar.get'](pillar_gate, False) %}

# --- {{ cap_key }} ---
{{ cap_meta.state_name }}:
  yay.installed:
    - pkgs: {{ packages[os_name][cap_key] | tojson }}
    - runas: {{ service_user }}
    - require:
      - yay: core_utils_packages
    - onfail_stop: True

{# Post-install: Enable service if specified #}
{%- if cap_meta.get('has_service') %}
{{ cap_meta.has_service }}_service:
  service.running:
    - name: {{ cap_meta.has_service }}
    - enable: True
    - require:
      - yay: {{ cap_meta.state_name }}
{%- endif %}

{# Post-install: Add user to groups if specified #}
{%- if cap_meta.get('has_user_groups') %}
{{ cap_key }}_user_groups:
  user.present:
    - name: {{ service_user }}
    - groups: {{ cap_meta.has_user_groups | tojson }}
    - remove_groups: False
    - require:
      - yay: {{ cap_meta.state_name }}
{%- endif %}

{%- endif %}{# pillar_gate #}
{%- endif %}{# packages exist #}
{%- endif %}{# not foundation and in capabilities #}
{%- endfor %}

# ============================================================================
# PACKAGES ABSENT: pillar-defined packages to remove (before extras)
# ============================================================================
{%- set packages_absent = salt['pillar.get']('packages_absent:' ~ os_name, {}) %}
{%- set absent_nodeps = packages_absent.get('nodeps', []) %}
{%- set absent_normal = packages_absent.get('normal', []) %}

{%- if absent_nodeps %}
packages_absent_nodeps:
  cmd.run:
    - name: pacman -Rdd --noconfirm {{ absent_nodeps | join(' ') }}
    - ignore_retcode: True
    - require:
      - yay: core_utils_packages
{%- endif %}

{%- if absent_normal %}
packages_absent_normal:
  pkg.removed:
    - pkgs: {{ absent_normal | tojson }}
    - require:
      - yay: core_utils_packages
{%- endif %}

# ============================================================================
# PACKAGES EXTRA: pillar-defined additional packages per capability
# ============================================================================
{%- set packages_extra = salt['pillar.get']('packages_extra:' ~ os_name, {}) %}
{%- for cap_key, extra_pkgs in packages_extra.items() %}
{%- if extra_pkgs %}

# --- extra: {{ cap_key }} ---
packages_extra_{{ cap_key }}:
  yay.installed:
    - pkgs: {{ extra_pkgs | tojson }}
    - runas: {{ service_user }}
    - require:
      - yay: core_utils_packages
{%- if absent_nodeps %}
      - cmd: packages_absent_nodeps
{%- endif %}
{%- endif %}
{%- endfor %}

{%- else %}

# Not an Arch-based system, skipping pacman configuration
pacman_config_skipped:
  test.nop:
    - name: Not an Arch-based system - skipping pacman config

{%- endif %}
