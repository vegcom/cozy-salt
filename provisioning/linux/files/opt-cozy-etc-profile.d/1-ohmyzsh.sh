#!/bin/sh
# Managed by Salt - DO NOT EDIT MANUALLY

if [ ! -n "$ZSH_VERSION" ]; then
  return 2>/dev/null
fi

if [ -s ${ZSH}/oh-my-zsh.sh ];then
  plugins=()
  # shellcheck disable=SC1090
  . ${ZSH}/oh-my-zsh.sh
fi
