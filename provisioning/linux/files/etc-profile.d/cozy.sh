#!/bin/bash
# /etc/profile.d/cozy.sh: System-wide shell environment configuration
# Managed by Salt - DO NOT EDIT MANUALLY

#------------------------------------------------------------------------------
# Editor Configuration
#------------------------------------------------------------------------------
export EDITOR=vim
export PAGER=cat

#------------------------------------------------------------------------------
# Bash History Configuration
#------------------------------------------------------------------------------
export HISTFILE="$HOME/.bash_history"
export HISTCONTROL=ignoredups:erasedups
export HISTSIZE=500000
export HISTFILESIZE=500000

#------------------------------------------------------------------------------
# NVM (Node Version Manager) Configuration
#------------------------------------------------------------------------------
export NVM_DIR="/opt/nvm"
export CONDA_AUTO_ACTIVATE_BASE=true

# Load NVM if installed
# shellcheck disable=SC1091
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
# shellcheck disable=SC1091
if [ "$SHELL" == "/bin/bash" ]; then
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
fi
#------------------------------------------------------------------------------
# Local user paths
#------------------------------------------------------------------------------
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"

#------------------------------------------------------------------------------
# Steam Big Picture overrides
#------------------------------------------------------------------------------
export STEAM_FORCE_DESKTOP_RETURN=1

