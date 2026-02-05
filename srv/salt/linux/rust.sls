# Linux Rust installation via rustup
# System-wide installation to /opt/rust with cargo, rustfmt, clippy
# Initialized via /etc/profile.d/rust.sh for all users
# Note: rustup rejects RUSTUP_HOME/CARGO_HOME in environment during installation
# Use inline env vars in commands only

{%- from "_macros/acl.sls" import cozy_acl %}

{# Path configuration from pillar with defaults #}
{% set rust_path = salt['pillar.get']('install_paths:rust:linux', '/opt/rust') %}

# Create rust directory first (rustup installer requires it to exist)
rust_directory:
  file.directory:
    - name: {{ rust_path }}
    - mode: "0755"
    - makedirs: True

# Download rustup-init script to /tmp
rust_download_script:
  cmd.run:
    - name: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o /tmp/rustup-init.sh && chmod +x /tmp/rustup-init.sh
    - creates: /tmp/rustup-init.sh
    - require:
      - file: rust_directory

# Install Rust system-wide
# RUSTUP_HOME - custom installation path for rustup
# CARGO_HOME - cargo home directory
# --no-modify-path - prevents auto-modification of shell profiles (we handle via /etc/profile.d)
rust_download_and_install:
  cmd.run:
    - name: RUSTUP_HOME={{ rust_path }} CARGO_HOME={{ rust_path }} /tmp/rustup-init.sh --no-modify-path -y
    - creates: {{ rust_path }}/bin/rustc
    - require:
      - cmd: rust_download_script

# Deploy Rust profile.d initialization script
rust_profile:
  file.managed:
    - name: /etc/profile.d/rust.sh
    - source: salt://linux/files/etc-profile.d/rust.sh
    - mode: "0644"

# Install Rust components via common orchestration
include:
  - common.rust

# Set ACLs for cozyusers group access
{{ cozy_acl(rust_path) }}
