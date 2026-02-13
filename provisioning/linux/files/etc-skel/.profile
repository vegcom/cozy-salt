#!/bin/bash
# ~/.profile
# Managed by Salt - DO NOT EDIT MANUALLY

if [[ -f "$HOME"/.bashrc.local ]]; then
# shellcheck disable=SC1091
  . "$HOME"/.profile.local
fi
