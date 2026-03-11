#!/bin/bash
# ~/.bashrc
# Managed by Salt - DO NOT EDIT MANUALLY

if [ -f /etc/bashrc ]; then
  # shellcheck disable=SC1091
  . /etc/bashrc
fi

if [ -f "$HOME"/.bashrc.local ]; then
  # shellcheck disable=SC1091
  . "$HOME"/.bashrc.local
fi
