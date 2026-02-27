#!/bin/zsh
# ~/.zshrc
# Managed by Salt - DO NOT EDIT MANUALLY

if [ -f /etc/zshrc ]; then
  # shellcheck disable=SC1091
  . /etc/zshrc
fi

if [ -f "$HOME"/.zshrc.local ]; then
  # shellcheck disable=SC1091
  . "$HOME"/.zshrc.local
fi
