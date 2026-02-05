# Tool Version Management
# Centralized version pinning for all tools across platforms
# Enables easy updates and version consistency

versions:
  # Node.js version manager
  # v0.40.1 released 2024-12-01, uses nvm-sh/nvm GitHub releases
  nvm:
    version: v0.40.1
    description: Node Version Manager (current stable)

  # Conda/Mamba package manager
  # 24.11.3-0 released 2025-01-15 (latest stable as of 2025-12-30)
  # Note: Previously had version skew (linux 23.11.0-0 vs windows 24.11.3-0)
  miniforge:
    version: 24.11.3-0
    description: Miniforge3 (conda-forge distribution, aligned across platforms)

  # Rust toolchain
  # Uses official rust-lang installer (latest approach)
  rust:
    version: stable
    description: Rust toolchain (always latest stable)

  # Windhawk - Windows customization tool
  # https://github.com/ramensoftware/windhawk/releases
  windhawk:
    version: 1.7.3
    description: Windows system-level customization (portable install)
