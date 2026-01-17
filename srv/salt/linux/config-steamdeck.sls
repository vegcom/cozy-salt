# Steam Deck (Valve Galileo) Hardware Configuration
# Only runs on detected Steam Deck hardware (DMI check)
# All settings are pillar-driven (class/galileo.sls or host overrides)

{% set is_galileo = grains.get('dmi', {}).get('System Information', {}).get('Manufacturer', '') == 'Valve' and
                    grains.get('dmi', {}).get('System Information', {}).get('Product Name', '') == 'Galileo' %}

{% if is_galileo %}

# =============================================================================
# DISPLAY ROTATION & TOUCH MAPPING
# =============================================================================
{% set display_config = salt['pillar.get']('display', {}) %}
{% set rotation_enabled = display_config.get('rotation', {}).get('enabled', False) %}
{% set rotation_angle = display_config.get('rotation', {}).get('angle', 'right') %}
{% set touch_enabled = display_config.get('touch_mapping', {}).get('enabled', False) %}

{% if rotation_enabled %}
# Apply xrandr rotation to primary display (touchscreen)
# Detects eDP-1 (Steam Deck internal display)
xrandr_rotate_display:
  cmd.run:
    - name: |
        output=$(xrandr | grep -E "^eDP|^HDMI|^DP" | grep " connected" | head -1 | cut -d' ' -f1)
        if [ -n "$output" ]; then
          xrandr --output "$output" --rotate {{ rotation_angle }}
        fi
    - unless: |
        xrandr | grep -q "eDP-1.*{{ rotation_angle }}\|HDMI.*{{ rotation_angle }}\|DP.*{{ rotation_angle }}"
    - onlyif: test -x /usr/bin/xrandr && test -n "$DISPLAY"
{% endif %}

{% if touch_enabled %}
# Map touchscreen coordinates to rotated display
# Detects FTS3528 (Steam Deck touchscreen) automatically
xrandr_map_touchscreen:
  cmd.run:
    - name: |
        # Find touchscreen device
        touch_dev=$(xinput list | grep -i "FTS3528\|touch" | grep pointer | head -1 | grep -oP 'id=\K\d+')
        if [ -n "$touch_dev" ]; then
          # Get primary display output name
          output=$(xrandr | grep -E "^eDP|^HDMI|^DP" | grep " connected" | head -1 | cut -d' ' -f1)
          if [ -n "$output" ]; then
            xinput map-to-output "$touch_dev" "$output"
          fi
        fi
    - onlyif: test -x /usr/bin/xinput && test -n "$DISPLAY"
{% endif %}

# =============================================================================
# STEAM INPUT CONFIGURATION
# =============================================================================
{% set steam_input_config = salt['pillar.get']('steam_input', {}) %}
{% set steam_config_enabled = steam_input_config.get('hardware_config', {}).get('enabled', False) %}

{% if steam_config_enabled %}
{% set user = salt['pillar.get']('user:name', 'deck') %}
{% set home = '/home/' ~ user %}

# Create Steam hardware config directory
steam_hardware_config_dir:
  file.directory:
    - name: {{ home }}/.config/Steam/hardware/steam_controller
    - user: {{ user }}
    - group: {{ user }}
    - mode: 755
    - makedirs: True

# Disable Steam input detection by symlinking to /dev/null
# This prevents Steam from auto-mapping controller input
steam_input_disable:
  file.symlink:
    - name: {{ home }}/.config/Steam/hardware/steam_controller/steam.input
    - target: /dev/null
    - user: {{ user }}
    - group: {{ user }}
    - require:
      - file: steam_hardware_config_dir
{% endif %}

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
