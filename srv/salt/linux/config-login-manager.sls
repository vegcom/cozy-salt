# Login Manager (SDDM) Configuration
# Manages SDDM login manager, theme deployment, and autologin
# Runs on all Linux systems with SDDM installed
# Pillar-gated: linux:login_manager:sddm:enabled

{% set sddm_enabled = salt['pillar.get']('linux:login_manager:sddm:enabled', false) %}

{% if sddm_enabled %}

# =============================================================================
# SDDM CONFIGURATION (Login Manager)
# =============================================================================

sddm_main_config:
  file.managed:
    - name: /etc/sddm.conf
    - contents: |
        # SDDM Configuration
        # Per-capability configs managed in /etc/sddm.conf.d/ via cozy-salt
        # This file kept minimal to avoid conflicts with .d/ directory
    - mode: 0644
    - user: root
    - group: root

sddm_wayland_conf:
  file.managed:
    - name: /etc/sddm.conf.d/wayland.conf
    - source: salt://linux/files/sddm/wayland.conf
    - makedirs: True

sddm_virtualkbd_conf:
  file.managed:
    - name: /etc/sddm.conf.d/virtualkbd.conf
    - source: salt://linux/files/sddm/virtualkbd.conf
    - makedirs: True

sddm_avatar_conf:
  file.managed:
    - name: /etc/sddm.conf.d/avatar.conf
    - source: salt://linux/files/sddm/avatar.conf
    - makedirs: True

sddm_theme_conf:
  file.managed:
    - name: /etc/sddm.conf.d/theme.conf
    - source: salt://linux/files/sddm/theme.conf
    - makedirs: True

sddm_cleanenv_conf:
  file.managed:
    - name: /etc/sddm.conf.d/cleanenv.conf
    - source: salt://linux/files/sddm/cleanenv.conf
    - makedirs: True

sddm_general_conf:
  file.managed:
    - name: /etc/sddm.conf.d/general.conf
    - source: salt://linux/files/sddm/general.conf
    - makedirs: True

# =============================================================================
# SDDM THEME DEPLOYMENT (Pillar-gated)
# =============================================================================
{% set sddm_theme = salt['pillar.get']('linux:login_manager:sddm:theme', 'astronaut') %}
{% set deploy_fonts = salt['pillar.get']('linux:login_manager:sddm:deploy_fonts', true) %}
{% set github_token = salt['pillar.get']('github:access_token', '') %}
{% set theme_url_map = {
  'astronaut': 'https://github.com/Keyitdev/sddm-astronaut-theme.git',
  'breeze': 'skip',
} %}
{% set theme_url = theme_url_map.get(sddm_theme, '') %}

{% if sddm_theme and theme_url and theme_url != 'skip' %}
sddm_theme:
  git.latest:
    - name: {{ theme_url }}
    - target: /usr/share/sddm/themes/sddm-{{ sddm_theme }}-theme
    - user: root
    - branch: main
    - force_clone: True

{% if deploy_fonts %}
sddm_theme_fonts:
  cmd.run:
    - name: cp -r /usr/share/sddm/themes/sddm-{{ sddm_theme }}-theme/Fonts/* /usr/share/fonts/ 2>/dev/null || true
    - require:
      - git: sddm_theme
    - onlyif: test -d /usr/share/sddm/themes/sddm-{{ sddm_theme }}-theme/Fonts

update_font_cache:
  cmd.run:
    - name: fc-cache -f -v
    - require:
      - cmd: sddm_theme_fonts
{% endif %}

{% else %}
# SDDM theme deployment disabled or theme not found in map
sddm_theme_disabled:
  test.nop:
    - name: SDDM theme deployment disabled or not found ({{ sddm_theme }})
{% endif %}

# =============================================================================
# AUTOLOGIN CONFIGURATION (Pillar-gated)
# =============================================================================
{% set autologin_user = salt['pillar.get']('linux:login_manager:autologin:user', false) %}
{% if autologin_user %}

sddm_autologin_conf:
  file.managed:
    - name: /etc/sddm.conf.d/autologin.conf
    - contents: |
        [Autologin]
        User={{ autologin_user }}
        Session=awesome
    - makedirs: True

{% else %}
# Autologin disabled (set linux:login_manager:autologin:user to enable)
sddm_autologin_disabled:
  test.nop:
    - name: Autologin disabled
{% endif %}

{% else %}

# SDDM login manager disabled in pillar
sddm_disabled:
  test.nop:
    - name: SDDM login manager disabled (set linux:login_manager:sddm:enabled to enable)

{% endif %}

# =============================================================================
# SYSTEMD SLEEP HOOK (Display rotation on wake - Steam Deck only)
# =============================================================================
{% set is_galileo = grains.get('dmi', {}).get('System Information', {}).get('Manufacturer', '') == 'Valve' and
                    grains.get('dmi', {}).get('System Information', {}).get('Product Name', '') == 'Galileo' %}

{% if is_galileo %}
steamdeck_sleep_hook:
  file.managed:
    - name: /usr/lib/systemd/system-sleep/deck.sh
    - source: salt://linux/files/steamdeck/deck.sh
    - mode: 0755
    - makedirs: True
{% endif %}
