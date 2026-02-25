# Installation Paths Configuration
# Centralized tool and installation paths for all platforms
# Uses Jinja for platform-aware defaults

{% set is_windows = grains['os_family'] == 'Windows' %}

# Windows-specific constants
windows:
  # System environment registry path (used by nvm, rust, miniforge)
  env_registry: 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'

install_paths:
  # Node.js version manager
  nvm:
    linux: /opt/nvm
    windows: C:\opt\nvm

  # Conda/Mamba package manager
  miniforge:
    linux: /opt/miniforge3
    windows: C:\opt\miniforge3

  # Rust toolchain
  rust:
    linux: /opt/rust
    windows: C:\opt\rust

  # Primary cozy-salt working directory
  cozy:
    linux: /opt/cozy/bin
    windows: C:\opt\cozy\bin

  # Homebrew (Linux-only)
  homebrew:
    linux: /home/linuxbrew/.linuxbrew
