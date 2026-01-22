# System Locale Configuration
# Generates specified locales via locale-gen on Linux systems

{% set locales = salt['pillar.get']('locales', ['en_US.UTF-8']) %}
{% set is_linux = grains['os_family'] in ['Debian', 'RedHat', 'Arch', 'Suse'] %}

{% if is_linux %}

# =============================================================================
# LOCALE GENERATION
# =============================================================================
# Deploy /etc/locale.gen with locales from pillar
locale_gen_config:
  file.managed:
    - name: /etc/locale.gen
    - mode: 644
    - user: root
    - group: root
    - contents: |
        # Locale generation configuration
        # Managed by cozy-salt - DO NOT EDIT MANUALLY
        # Add or remove locale codes and run: locale-gen

        {%- for locale in locales %}
        {{ locale }}
        {%- endfor %}

# Generate all configured locales
generate_locales:
  cmd.run:
    - name: locale-gen
    - onchanges:
      - file: locale_gen_config

{% else %}

# Not a Linux system, skipping locale configuration
locale_config_skipped:
  test.nop:
    - name: Not a supported Linux system - skipping locale config

{% endif %}
