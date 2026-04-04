#!/bin/bash
# /etc/profile.d/cozy.sh: System-wide shell environment configuration
# Managed by Salt - DO NOT EDIT MANUALLY

#------------------------------------------------------------------------------
# User TMPDIR
#------------------------------------------------------------------------------

_TMPDIR=${HOME}/scratch
if [ -d "$_TMPDIR" ]; then
  TMPDIR=${_TMPDIR}
  USER_TMPDIR=${_TMPDIR}
else
  TMPDIR=/tmp
fi
export TMPDIR USER_TMPDIR

#------------------------------------------------------------------------------
# k3s
#------------------------------------------------------------------------------
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml:${HOME}/.kube/config

#------------------------------------------------------------------------------
# Editor Configuration
#------------------------------------------------------------------------------
export EDITOR=vim
export PAGER=cat

#------------------------------------------------------------------------------
# Shell History Configuration
#------------------------------------------------------------------------------
export HISTFILE="$HOME/.$(basename $SHELL)-history"
export HISTCONTROL=ignoredups:erasedups
export HISTSIZE=500000
export HISTFILESIZE=500000
export SAVEHIST=500000

#------------------------------------------------------------------------------
# NVM (Node Version Manager) Configuration
#------------------------------------------------------------------------------
export NVM_DIR="/opt/nvm"
# Load NVM if installed
# shellcheck disable=SC1091
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
# shellcheck disable=SC1091
if [ -n "$BASH_VERSION" ]; then
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
fi

#------------------------------------------------------------------------------
# Python PIP/Conda
#------------------------------------------------------------------------------
export PIP_CACHE_DIR="${TMPDIR}/pip-cache"
export CONDA_AUTO_ACTIVATE_BASE=true

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
export COZY_PATH=/opt/cozy
export COZY_ETC=${COZY_PATH}/etc
export COZY_BIN=${COZY_PATH}/bin
export COZY_DOCKER=${COZY_PATH}/docker

#------------------------------------------------------------------------------
# PATH definition
#------------------------------------------------------------------------------
export PATH="/usr/lib/colorgcc/bin/:/usr/lib/ccache/bin:$HOME/bin:$HOME/.local/bin:$PATH"
