# Windows Rust installation via rustup-init
# System-wide installation to C:\opt\rust (consistent with Linux /opt/rust)
# Environment variables configured as system-wide for all users

{% set rust_path = 'C:\\opt\\rust' %}
{% set rust_bin = 'C:\\opt\\rust\\bin' %}
{% set current_path = salt['reg.read_value']('HKLM',"SYSTEM\CurrentControlSet\Control\Session Manager\Environment",'Path').get('vdata','') %}

# FIX: Add rust bin directory to PATH
{% set paths = current_path.split(';') %}

{% if rust_bin not in paths %}
  {% do paths.append(rust_bin) %}
{% endif %}

{% set merged_paths = ';'.join(paths) %}

# Create C:\opt\rust directory
rust_directory:
  file.directory:
    - name: {{ rust_path }}
    - makedirs: True

# Download rustup-init.exe
rust_download:
  cmd.run:
    # XXX: Changed powershell to pwsh. powershell has no double ampersant or bar operator
    # XXX: $env:TEMP can not have single quotes
    # XXX: C:\Windows\Temp\ =/= $env:TEMP
    - name: pwsh -Command "Invoke-WebRequest -Uri https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-msvc/rustup-init.exe -OutFile C:\opt\rust\rustup-init.exe
    - creates: C:\opt\rust\rustup-init.exe
    - require:
      - file: rust_directory

# Install Rust to C:\opt\rust using rustup-init
# RUSTUP_HOME and CARGO_HOME set inline to custom path
# --no-modify-path suppresses shell profile modifications (we handle via environment variables)
rust_install:
  cmd.run:
    # XXX: Changed powershell to pwsh. powershell has no double ampersant or bar operator
    - name: pwsh -Command "& { $env:RUSTUP_HOME='C:\opt\rust'; $env:CARGO_HOME='C:\opt\rust'; C:\opt\rust\rustup-init.exe -y --no-modify-path }"
    - creates: C:\opt\rust\bin\rustc.exe
    - require:
      - cmd: rust_download

# Set system-wide environment variables for Rust
# HKEY_LOCAL_MACHINE ensures all users have access
rust_rustup_home:
  reg.present:
    - name: HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment
    - vname: RUSTUP_HOME
    - vdata: {{ rust_path }}
    - vtype: REG_SZ
    - require:
      - cmd: rust_install

rust_cargo_home:
  reg.present:
    - name: HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment
    - vname: CARGO_HOME
    - vdata: {{ rust_path }}
    - vtype: REG_SZ
    - require:
      - cmd: rust_install

# FIX: Add Rust bin to system PATH
rust_path_update:
  reg.present:
    - name: HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment
    - vname: Path
    - vtype: REG_EXPAND_SZ
    - vdata: {{ merged_paths }}
    - require:
      - cmd: rust_install