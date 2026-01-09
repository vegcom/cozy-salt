#!/bin/bash
# Git environment variables initialization
# Exports GIT_NAME and GIT_EMAIL from global git config for all users
# Sourced by /etc/profile.d on shell initialization

# Only set if git is installed and user has global git config
if command -v git &> /dev/null; then
  export GIT_NAME="$(git config --global user.name 2>/dev/null)"
  export GIT_EMAIL="$(git config --global user.email 2>/dev/null)"
fi
