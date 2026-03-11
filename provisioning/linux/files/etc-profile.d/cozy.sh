#!/bin/bash
# /etc/profile.d/cozy.sh: System-wide shell environment configuration
# Managed by Salt - DO NOT EDIT MANUALLY

#------------------------------------------------------------------------------
# User TMPDIR
#------------------------------------------------------------------------------

_TMPDIR=${HOME}/scratch
if [ -d "$_TMPDIR" ]; then
  TMPDIR=/tmp
else
  TMPDIR=${_TMPDIR}
  USER_TMPDIR=${_TMPDIR}
fi
export TMPDIR USER_TMPDIR

#------------------------------------------------------------------------------
# Editor Configuration
#------------------------------------------------------------------------------
export EDITOR=vim
export PAGER=cat

#------------------------------------------------------------------------------
# Shell History Configuration
#------------------------------------------------------------------------------
export HISTFILE="$HOME/.history"
export HISTCONTROL=ignoredups:erasedups
export HISTSIZE=500000
export HISTFILESIZE=500000
export SAVEHIST=500000

#------------------------------------------------------------------------------
# NVM (Node Version Manager) Configuration
#------------------------------------------------------------------------------
export NVM_DIR="/opt/nvm"
export CONDA_AUTO_ACTIVATE_BASE=true

# Load NVM if installed
# shellcheck disable=SC1091
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
# shellcheck disable=SC1091
if [ -n "$BASH_VERSION" ]; then
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
fi

#------------------------------------------------------------------------------
# Python PIP
#------------------------------------------------------------------------------

export PIP_CACHE_DIR="${TMPDIR}/pip-cache"

#------------------------------------------------------------------------------
# Steam Big Picture overrides
#------------------------------------------------------------------------------
export STEAM_FORCE_DESKTOP_RETURN=1

#------------------------------------------------------------------------------
# Git discovery across filesystem
#------------------------------------------------------------------------------
export GIT_DISCOVERY_ACROSS_FILESYSTEM=1

#------------------------------------------------------------------------------
# Tmux
#-----------------------------------------------------------------------------
export TMUX_TMPDIR="${TMPDIR}/tmux"

#------------------------------------------------------------------------------
# Compile
#------------------------------------------------------------------------------
export CCACHE_DIR="${TMPDIR}/ccache"
export CCACHE_SLOPPINESS="locale,time_macros"
export CCACHE_PATH="/usr/bin"
export CCACHE_MAXSIZE="4G"
export CCACHE_COMPRESS=true

export CC="ccache gcc"
export CXX="ccache g++"
export LD="ccache ld"
export FC="ccache gfortran"

#------------------------------------------------------------------------------
# Local paths
#------------------------------------------------------------------------------
export PATH="/usr/lib/colorgcc/bin/:/usr/lib/ccache/bin:$HOME/bin:$HOME/.local/bin:$PATH"
