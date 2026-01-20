# Steam Deck (Valve Galileo) Hardware Configuration
# Only runs on detected Steam Deck hardware (DMI check)
# Deploys SDDM configs and display/input management via systemd sleep hooks

{% set is_galileo = grains.get('dmi', {}).get('System Information', {}).get('Manufacturer', '') == 'Valve' and
                    grains.get('dmi', {}).get('System Information', {}).get('Product Name', '') == 'Galileo' %}

{% if is_galileo %}

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
    - source: salt://provisioning/steamdeck/wayland.conf
    - makedirs: True

sddm_virtualkbd_conf:
  file.managed:
    - name: /etc/sddm.conf.d/virtualkbd.conf
    - source: salt://provisioning/steamdeck/virtualkbd.conf
    - makedirs: True

sddm_avatar_conf:
  file.managed:
    - name: /etc/sddm.conf.d/avatar.conf
    - source: salt://provisioning/steamdeck/avatar.conf
    - makedirs: True

sddm_theme_conf:
  file.managed:
    - name: /etc/sddm.conf.d/theme.conf
    - source: salt://provisioning/steamdeck/theme.conf
    - makedirs: True

sddm_cleanenv_conf:
  file.managed:
    - name: /etc/sddm.conf.d/cleanenv.conf
    - source: salt://provisioning/steamdeck/cleanenv.conf
    - makedirs: True

sddm_general_conf:
  file.managed:
    - name: /etc/sddm.conf.d/general.conf
    - source: salt://provisioning/steamdeck/general.conf
    - makedirs: True

# =============================================================================
# ASTRONAUT THEME DEPLOYMENT
# =============================================================================

sddm_astronaut_theme:
  git.latest:
    - name: https://github.com/Keyitdev/sddm-astronaut-theme.git
    - target: /usr/share/sddm/themes/sddm-astronaut-theme
    - user: root

sddm_astronaut_fonts:
  cmd.run:
    - name: cp -r /usr/share/sddm/themes/sddm-astronaut-theme/Fonts/* /usr/share/fonts/
    - require:
      - git: sddm_astronaut_theme
    - onlyif: test -d /usr/share/sddm/themes/sddm-astronaut-theme/Fonts

update_font_cache:
  cmd.run:
    - name: fc-cache -f -v
    - require:
      - cmd: sddm_astronaut_fonts

# =============================================================================
# AUTOLOGIN CONFIGURATION (Optional via pillar gate)
# =============================================================================
{% set autologin_user = salt['pillar.get']('steamdeck:autologin:user', False) %}
{% if autologin_user %}

sddm_autologin_conf:
  file.managed:
    - name: /etc/sddm.conf.d/autologin.conf
    - contents: |
        [Autologin]
        User={{ autologin_user }}
        Session=awesome
    - makedirs: True

{% endif %}

# =============================================================================
# SYSTEMD SLEEP HOOK (Display rotation on wake)
# =============================================================================

steamdeck_sleep_hook:
  file.managed:
    - name: /usr/lib/systemd/system-sleep/deck.sh
    - source: salt://provisioning/steamdeck/deck.sh
    - mode: 0755
    - makedirs: True

# =============================================================================
# BLUETOOTH CONFIGURATION
# =============================================================================
{% set bluetooth_config = salt['pillar.get']('bluetooth', {}) %}
{% set bluetooth_enabled = bluetooth_config.get('enabled', True) %}

{% if bluetooth_enabled %}
# Enable and start Bluetooth service
bluetooth_service:
  service.running:
    - name: bluetooth
    - enable: True

# Configure Bluetooth auto-enable on boot
bluetooth_main_config:
  file.managed:
    - name: /etc/bluetooth/main.conf
    - mode: 644
    - makedirs: True
    - contents: |
        # Bluetooth configuration (managed by cozy-salt on Steam Deck)
        [General]
        DiscoverableTimeout = 0
        Discoverable = false
        AlwaysPairable = true

        [Policy]
        AutoEnable = true
    - require:
      - service: bluetooth_service
{% else %}
# Bluetooth disabled in pillar
bluetooth_disabled:
  test.nop:
    - name: Bluetooth configuration disabled (check pillar display:bluetooth:enabled)
{% endif %}

{% else %}
# Not a Steam Deck (Valve Galileo) - skip all Steam Deck specific configuration
not_steamdeck:
  test.nop:
    - name: Not detected as Steam Deck (Valve Galileo) - skipping hardware config
{% endif %}
