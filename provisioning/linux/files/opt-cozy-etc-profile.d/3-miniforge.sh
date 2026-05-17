#!/bin/sh
# Managed by Salt - DO NOT EDIT MANUALLY

export CONDA_PKGS_BASE="${TMPDIR}/conda"
export CONDA_PKGS_DIRS="${CONDA_PKGS_BASE}/${UID:-$(id -u)}"

if [ -n "$BASH_VERSION" ] || [ -n "$ZSH_VERSION" ] && [ -n "$SHELL" ] ; then
  # shellcheck disable=SC2046
  eval "$($CONDA_EXE shell.$(basename ${SHELL}) hook)" >/dev/null
fi
