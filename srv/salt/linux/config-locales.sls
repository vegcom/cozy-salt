# System Locale Configuration
# Debian/Ubuntu: locale-gen via /etc/locale.gen
# RHEL/Rocky: localedef per locale

{% set locales = salt['pillar.get']('locales', ['en_US.UTF-8']) %}
{% set os_family = grains['os_family'] %}
{% set is_linux = os_family in ['Debian', 'RedHat', 'Arch', 'Suse'] %}

{% if is_linux %}

# =============================================================================
# LOCALE GENERATION
# =============================================================================

{% if os_family == 'Debian' %}

# Deploy /etc/locale.gen with locales from pillar
locale_gen_config:
  file.managed:
    - name: /etc/locale.gen
    - mode: "0644"
    - user: root
    - group: root
    - contents: |
        {%- for locale in locales %}
        {{ locale }}
        {%- endfor %}

# Purge all locales
purge_locales:
  cmd.run:
    - name: locale-gen --purge
    - onchanges:
      - file: locale_gen_config

# Generate all configured locales
generate_locales:
  cmd.run:
    - name: locale-gen
    - onchanges:
      - file: locale_gen_config
    - require:
      - cmd: purge_locales

{% elif os_family == 'RedHat' %}

# RHEL/Rocky: generate each locale via localedef
{% for locale in locales %}
{% set parts = locale.split('.') %}
{% set lang = parts[0] %}
{% set charset = parts[1] if parts | length > 1 else 'UTF-8' %}
generate_locale_{{ locale | replace('.', '_') | replace('-', '_') }}:
  cmd.run:
    - name: localedef -c -i {{ lang }} -f {{ charset }} {{ locale }}
    - unless: localedef --list-archive | grep -q '^{{ locale }}$'
{% endfor %}

{% else %}

locale_config_skipped:
  test.nop:
    - name: Locale generation not configured for os_family={{ os_family }}

{% endif %}

{% else %}

# Not a Linux system, skipping locale configuration
locale_config_skipped:
  test.nop:
    - name: Not a supported Linux system - skipping locale config

{% endif %}
