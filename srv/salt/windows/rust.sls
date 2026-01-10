# Windows Rust installation via rustup-init
# System-wide installation to C:\opt\rust (consistent with Linux /opt/rust)
# Environment variables configured as system-wide for all users
# PATH updates handled by windows.paths (avoids race conditions)

{# Path configuration from pillar with defaults #}
{% set rust_path = salt['pillar.get']('install_paths:rust:windows', 'C:\\opt\\rust') %}
{% set env_registry = salt['pillar.get']('windows:env_registry', 'HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment') %}

# Create C:\opt\rust directory
rust_directory:
  file.directory:
    - name: {{ rust_path }}
    - makedirs: True

# Download rustup-init.exe
rust_download:
  cmd.run:
    - name: pwsh -Command "Invoke-WebRequest -Uri https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-msvc/rustup-init.exe -OutFile {{ rust_path }}\rustup-init.exe"
    - creates: {{ rust_path }}\rustup-init.exe
    - require:
      - file: rust_directory

# Install Rust using rustup-init
# RUSTUP_HOME and CARGO_HOME set inline to custom path
# --no-modify-path suppresses shell profile modifications (we handle via environment variables)
rust_install:
  cmd.run:
    - name: pwsh -Command "& { $env:RUSTUP_HOME='{{ rust_path }}'; $env:CARGO_HOME='{{ rust_path }}'; {{ rust_path }}\rustup-init.exe -y --no-modify-path }"
    - creates: {{ rust_path }}\bin\rustc.exe
    - require:
      - cmd: rust_download

# Set system-wide environment variables for Rust
# HKEY_LOCAL_MACHINE ensures all users have access
rust_rustup_home:
  reg.present:
    - name: {{ env_registry }}
    - vname: RUSTUP_HOME
    - vdata: {{ rust_path }}
    - vtype: REG_SZ
    - require:
      - cmd: rust_install

rust_cargo_home:
  reg.present:
    - name: {{ env_registry }}
    - vname: CARGO_HOME
    - vdata: {{ rust_path }}
    - vtype: REG_SZ
    - require:
      - cmd: rust_install

# PATH updates handled by windows.paths
include:
  - windows.paths