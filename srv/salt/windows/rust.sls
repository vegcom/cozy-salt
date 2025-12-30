# Windows Rust installation via rustup-init
# System-wide installation to C:\opt\rust (consistent with Linux /opt/rust)
# Environment variables configured as system-wide for all users

# Create C:\opt\rust directory
rust_directory:
  file.directory:
    - name: C:\opt\rust
    - makedirs: True

# Download rustup-init.exe
rust_download:
  cmd.run:
    - name: powershell -Command "Invoke-WebRequest -Uri 'https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-msvc/rustup-init.exe' -OutFile 'C:\opt\rust\rustup-init.exe'"
    - creates: C:\opt\rust\rustup-init.exe
    - require:
      - file: rust_directory

# Install Rust to C:\opt\rust using rustup-init
# RUSTUP_HOME and CARGO_HOME set inline to custom path
# --no-modify-path suppresses shell profile modifications (we handle via environment variables)
rust_install:
  cmd.run:
    - name: powershell -Command "& { $env:RUSTUP_HOME='C:\opt\rust'; $env:CARGO_HOME='C:\opt\rust'; C:\opt\rust\rustup-init.exe -y --no-modify-path }"
    - creates: C:\opt\rust\bin\rustc.exe
    - require:
      - cmd: rust_download

# Set system-wide environment variables for Rust
# HKEY_LOCAL_MACHINE ensures all users have access
rust_environment_variables:
  reg.present:
    - name: HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment
    - vtype: REG_SZ
    - entries:
      - RUSTUP_HOME: C:\opt\rust
      - CARGO_HOME: C:\opt\rust
    - require:
      - cmd: rust_install
