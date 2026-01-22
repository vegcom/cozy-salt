#!/bin/bash
# ~/.profile :  Managed by salt
#------------------------------------------------------------------------------
export HISTFILE="$HOME/.bash_history"
export HISTCONTROL=ignoredups:erasedups
export HISTSIZE=500000
export HISTFILESIZE=500000
export NVM_DIR="/opt/nvm"
export CONDA_AUTO_ACTIVATE_BASE=true
#------------------------------------------------------------------------------
# shellcheck disable=SC1091
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
# shellcheck disable=SC1091
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Source usrs own .profile.local
# shellcheck disable=SC1091
source "$HOME"/.profile.local
