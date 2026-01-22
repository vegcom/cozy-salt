# Rust Toolchain - Windows

Rust installation to `C:\opt\rust` via rustup-init on Windows.

## Location

- **State**: `srv/salt/windows/rust.sls`
- **Include**: `windows.init`
- **Components**: `common.rust`

## Installation

Uses official rustup-init.exe:
<https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-msvc/rustup-init.exe>

| Item          | Location                    |
| ------------- | --------------------------- |
| Rust binaries | `C:\opt\rust\bin`           |
| Cargo         | `C:\opt\rust\bin\cargo.exe` |
| Toolchain     | Latest stable by default    |

## Pillar Configuration

```yaml
rust:
  toolchain: stable # or nightly, beta
```

## Installed Components

Via `common.rust`:

- rustc: Compiler
- cargo: Package manager
- clippy: Linter
- rustfmt: Code formatter

## Usage

```cmd
rustc --version    REM Verify installation
cargo new myproj   REM Create project
cargo build       REM Build
```

## Notes

- Requires .NET Framework (usually present)
- PATH auto-configured by installer
- Affects all users on system
- Visual C++ build tools recommended for some crates
