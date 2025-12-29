# Starship shell prompt initialization
# Managed by Salt - DO NOT EDIT MANUALLY

# Only initialize starship in bash shells (not sh, zsh, etc when sourced)
if [ -n "$BASH_VERSION" ]; then
    if ! which starship >/dev/null 2>&1; then
        sh <(curl -sS https://starship.rs/install.sh) --force 2>/dev/null || true
    fi

    if [ ! -f "$HOME/.config/starship.toml" ]; then
        mkdir -p "$HOME/.config"
    fi

    eval "$(starship init bash)" 2>/dev/null || true
fi