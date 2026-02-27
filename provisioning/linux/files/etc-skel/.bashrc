#!/bin/bash
# ~/.bashrc
# Managed by Salt - DO NOT EDIT MANUALLY

if [ -f /etc/bash.bashrc ]; then
  # shellcheck disable=SC1091
  . /etc/bash.bashrc
fi

if [ -f "$HOME"/.bashrc.local ]; then
  # shellcheck disable=SC1091
  . "$HOME"/.bashrc.local
fi
