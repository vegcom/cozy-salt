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

# Ensure locales package is present (provides locale-gen)
locales_pkg:
  pkg.installed:
    - name: locales

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
    - require:
      - pkg: locales_pkg

# Purge all locales
purge_locales:
  cmd.run:
    - name: locale-gen --purge
    - onchanges:
      - file: locale_gen_config
    - require:
      - pkg: locales_pkg

# Generate all configured locales
generate_locales:
  cmd.run:
    - name: locale-gen
    - onchanges:
      - file: locale_gen_config
    - require:
      - cmd: purge_locales

{% elif os_family == 'RedHat' %}

# RHEL/Rocky: install glibc-langpack-XX per unique language code
{% set lang_codes = [] %}
{% for locale in locales %}
{% set lang_code = locale.split('_')[0] %}
{% if lang_code not in lang_codes %}
{% do lang_codes.append(lang_code) %}
install_langpack_{{ lang_code }}:
  pkg.installed:
    - name: glibc-langpack-{{ lang_code }}
{% endif %}
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
