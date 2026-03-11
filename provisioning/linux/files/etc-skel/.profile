#!/bin/bash
# ~/.profile
# Managed by Salt - DO NOT EDIT MANUALLY

if [ -f /etc/profile ]; then
# shellcheck disable=SC1091
  . /etc/profile
fi

if [ -f "$HOME"/.profile.local ]; then
# shellcheck disable=SC1091
  . "$HOME"/.profile.local
fi
