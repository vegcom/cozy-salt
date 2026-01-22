# Rust Component Installation

Cross-platform Rust component management: clippy, rustfmt, etc.

## Location

- **State**: `srv/salt/common/rust.sls`
- **Include**: `common.init`

## Installs Components

| Component | Purpose                                   |
| --------- | ----------------------------------------- |
| clippy    | Linter for Rust (catches common mistakes) |
| rustfmt   | Code formatter (consistent style)         |
| rust-std  | Standard library for target platforms     |

## Usage

```bash
cargo clippy          # Run linter
rustfmt src/main.rs   # Format file
cargo fmt             # Format project
```

## Platform Support

- **Linux**: Via `/opt/rust/bin/` (after rust-init.sh)
- **Windows**: Via `C:\opt\rust\bin\`

## Notes

- Requires Rust installation first (linux.rust or windows.rust)
- rustup manages components
- All users can access installed components
- Must run after Rust setup completes
