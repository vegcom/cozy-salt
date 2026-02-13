#!/bin/zsh
# ~/zshrc
# Managed by Salt - DO NOT EDIT MANUALLY

emulate zsh
autoload -Uz compinit
compinit -u

if [[ -f "$HOME"/.zshrc.local ]]; then
  # shellcheck disable=SC1091
  source "$HOME"/.zshrc.local
fi
