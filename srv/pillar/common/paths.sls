# Installation Paths Configuration
# Centralized tool and installation paths for all platforms
# Uses Jinja for platform-aware defaults

{%- set is_windows = grains['os_family'] == 'Windows' %}

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

  docker:
    linux: /opt/cozy/docker
    windows: C:\opt\cozy\docker

  # Salt onedir installation
  salt:
    linux: /opt/saltstack/salt
    windows: 'C:\Program Files\Salt Project\Salt'

  # Homebrew (Linux-only)
  homebrew:
    linux: /home/linuxbrew/.linuxbrew

cache_paths:
  pip:
    windows: C:\opt\cozy\cache\miniforge
    linux: /opt/cozy/cache/miniforge

config_paths:
  pip:
    windows: C:\ProgramData\pip\pip.ini
    linux: /etc/pip.conf
  salt:
    linux: /etc/salt
    windows: 'C:\salt\conf'
  cozy:
    windows: C:\opt\cozy\etc
    linux: /opt/cozy/etc
  cozy_profile:
    linux: /opt/cozy/etc/profile.d
  cozy_environment:
    linux: /opt/cozy/etc/environment.d
  docker:
    linux: /etc/docker/daemon.json
    windows: '$HOME\.docker\daemon.json'
