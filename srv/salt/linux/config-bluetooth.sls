# Bluetooth Configuration
# Manages bluetooth service and configuration
# Runs on all Linux systems with bluetooth support
# Pillar-gated: linux:bluetooth:enabled

{% set bluetooth_enabled = salt['pillar.get']('linux:bluetooth:enabled', false) %}

{% if bluetooth_enabled %}

# =============================================================================
# BLUETOOTH SERVICE
# =============================================================================
# Enable and start Bluetooth service
bluetooth_service:
  service.running:
    - name: bluetooth
    - enable: True

# =============================================================================
# BLUETOOTH CONFIGURATION
# =============================================================================
# Configure Bluetooth auto-enable on boot
bluetooth_main_config:
  file.managed:
    - name: /etc/bluetooth/main.conf
    - mode: 644
    - makedirs: True
    - contents: |
        # Bluetooth configuration (managed by cozy-salt)
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
    - name: Bluetooth disabled (set linux:bluetooth:enabled to enable)

{% endif %}
