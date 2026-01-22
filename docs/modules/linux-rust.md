# Rust Toolchain - Linux

System-wide Rust installation to `/opt/rust` via rustup.

## Location

- **State**: `srv/salt/linux/rust.sls`
- **Include**: `linux.init`
- **Components**: `common.rust`

## Installation

Uses official rustup: https://rustup.rs/

| Item | Location |
|------|----------|
| Rust binary | `/opt/rust/bin` |
| Shell init | `/etc/profile.d/rust-init.sh` |
| Toolchain | Latest stable by default |

## Installed Components

Via `common.rust`:
- rustc: Rust compiler
- cargo: Package manager
- clippy: Linter (installed by common.rust)
- rustfmt: Code formatter (installed by common.rust)

## Pillar Configuration

```yaml
rust:
  toolchain: stable  # or nightly, beta
```

## Usage

```bash
rustc --version     # Verify installation
cargo new myproject # Create new project
cargo build        # Build project
```

## Notes

- Requires curl (installed via core_utils)
- Shell profile auto-sources Rust on login
- System-wide installation for all users
- Different from Windows rustup-init (separate state)
- clippy and rustfmt added via `common.rust` state
