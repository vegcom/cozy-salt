# Common Rust component orchestration
# Installs additional rustup components (clippy, rustfmt) cross-platform
# Platform-specific Rust installation delegated to linux.rust or windows.rust

{# Path configuration from pillar with defaults - platform-specific #}
{% if grains['os_family'] == 'Windows' %}
{% set rust_path = salt['pillar.get']('install_paths:rust:windows', 'C:\\opt\\rust') %}
{% set rustup_bin = rust_path ~ '\\bin\\rustup.exe' %}
{% set clippy_check = rust_path ~ '\\bin\\clippy-driver.exe' %}
{% else %}
{% set rust_path = salt['pillar.get']('install_paths:rust:linux', '/opt/rust') %}
{% set rustup_bin = rust_path ~ '/bin/rustup' %}
{% set clippy_check = rust_path ~ '/bin/clippy-driver' %}
{% endif %}

# Install additional Rust components (clippy, rustfmt)
# These are installed via rustup after initial Rust setup
rust_install_components:
  cmd.run:
    {% if grains['os_family'] == 'Windows' %}
    - name: pwsh -Command "& { $env:RUSTUP_HOME='{{ rust_path }}'; $env:CARGO_HOME='{{ rust_path }}'; {{ rustup_bin }} component add clippy rustfmt }"
    - unless: pwsh -Command "Test-Path '{{ clippy_check }}'"
    - require:
      - cmd: rust_install
    {% else %}
    - name: |
        RUSTUP_HOME={{ rust_path }} CARGO_HOME={{ rust_path }} {{ rustup_bin }} component add clippy rustfmt
    - unless: test -f {{ clippy_check }}
    - require:
      - cmd: rust_download_and_install
    {% endif %}
