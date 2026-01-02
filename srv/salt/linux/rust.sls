# Linux Rust installation via rustup
# System-wide installation to /opt/rust with cargo, rustfmt, clippy
# Initialized via /etc/profile.d/rust.sh for all users
# Note: rustup rejects RUSTUP_HOME/CARGO_HOME in environment during installation
# Use inline env vars in commands only

# Create /opt/rust directory first (rustup installer requires it to exist)
rust_directory:
  file.directory:
    - name: /opt/rust
    - mode: 755
    - makedirs: True

# Download rustup-init script to /tmp
rust_download_script:
  cmd.run:
    - name: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o /tmp/rustup-init.sh && chmod +x /tmp/rustup-init.sh
    - creates: /tmp/rustup-init.sh
    - require:
      - file: rust_directory

# Install Rust to /opt/rust system-wide
# RUSTUP_HOME=/opt/rust - custom installation path for rustup
# CARGO_HOME=/opt/rust - cargo home directory
# --no-modify-path - prevents auto-modification of shell profiles (we handle via /etc/profile.d)
rust_download_and_install:
  cmd.run:
    - name: RUSTUP_HOME=/opt/rust CARGO_HOME=/opt/rust /tmp/rustup-init.sh --no-modify-path -y
    - creates: /opt/rust/bin/rustc
    - require:
      - cmd: rust_download_script

# Deploy Rust profile.d initialization script
rust_profile:
  file.managed:
    - name: /etc/profile.d/rust.sh
    - source: salt://provisioning/linux/files/etc-profile.d/rust.sh
    - mode: 644

# Install additional Rust components (clippy, rustfmt)
# These are installed via rustup after initial Rust setup
rust_install_components:
  cmd.run:
    - name: |
        RUSTUP_HOME=/opt/rust CARGO_HOME=/opt/rust /opt/rust/bin/rustup component add clippy rustfmt
    - require:
      - cmd: rust_download_and_install
      - file: rust_profile
    - unless: test -f /opt/rust/bin/clippy-driver
