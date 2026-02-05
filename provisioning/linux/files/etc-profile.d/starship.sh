#!/bin/bash
# Starship shell prompt initialization
# Managed by Salt - DO NOT EDIT MANUALLY

# # Only initialize starship in bash shells (not sh, zsh, etc when sourced)
# if [ -n "$BASH_VERSION" ]; then
#     if ! which starship >/dev/null 2>&1; then
#         # Download and install starship (non-interactive with -y flag)
#         # Bash will not work, only SH
#         (curl -sS https://raw.githubusercontent.com/starship/starship/master/install/install.sh 2>/dev/null | TERM=dumb sh -s -- -y 2>/dev/null) || true
#     fi

# if [ ! -f "$HOME/.config/starship.toml" ]; then
#     mkdir -p "$HOME/.config"
# fi


# if [ "$SHELL" == "/bin/bash" ];then
#   eval "$(starship init bash)" 2>/dev/null || true
# elif [ "$SHELL" == "/bin/zsh" ];then
#   eval "$(starship init zsh)" 2>/dev/null || true
# fi

