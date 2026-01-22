#!/bin/bash
# Rust (rustup) system-wide initialization
# Manages environment for all users to use system-wide /opt/rust installation
# Managed by Salt - DO NOT EDIT MANUALLY

# Set Rust directories
export RUSTUP_HOME="/opt/rust"
export CARGO_HOME="/opt/rust"

# Add Rust binaries to PATH
# rustup, cargo, rustc, clippy-driver, rustfmt, etc. installed in /opt/rust/bin
if [ -d "$RUSTUP_HOME/bin" ]; then
    export PATH="$RUSTUP_HOME/bin:$PATH"
fi
