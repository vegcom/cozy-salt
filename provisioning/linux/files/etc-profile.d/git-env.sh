#!/bin/bash
# Git environment variables initialization
# Exports GIT_NAME and GIT_EMAIL from global git config for all users
# Sourced by /etc/profile.d on shell initialization
# Managed by Salt - DO NOT EDIT MANUALLY

# Only set if git is installed and user has global git config
if command -v git &> /dev/null; then
  GIT_NAME="$(git config --global user.name 2>/dev/null)"
  GIT_EMAIL="$(git config --global user.email 2>/dev/null)"
  export GIT_EMAIL
  export GIT_NAME
fi
