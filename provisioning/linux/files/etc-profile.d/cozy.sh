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
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

#------------------------------------------------------------------------------
# Functions
#------------------------------------------------------------------------------
gclean() {
  # Marker text to stop at; default stays your original
  local marker="${1}"

  if [[ -z ${marker} ]];then
    echo "Usage: gclean <marker>"
    return 1
  fi

  _MARK="$marker" git filter-repo --force --message-callback '
import os

marker = os.environ.get("_MARK", "").encode()

lines = message.split(b"\n")
cleaned = []

for l in lines:
    if marker and marker in l:
        break
    cleaned.append(l)

return b"\n".join(cleaned)
'
}

export gclean

t(){
  if [[ -d ${PWD}/.git ]] ; then
    _name="$(basename "${PWD:-$(pwd)}")"
    tmux new -s "${_name}"
  fi
}

export t

#------------------------------------------------------------------------------
# Aliases
#------------------------------------------------------------------------------

