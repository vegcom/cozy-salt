#!/bin/sh
# Managed by Salt - DO NOT EDIT MANUALLY

# shellcheck disable=SC2046

export CONDA_PKGS_BASE="${TMPDIR}/conda"
export CONDA_PKGS_DIRS="${CONDA_PKGS_BASE}/${UID:-$(id -u)}"

if [ -n "$BASH_VERSION" ] || [ -n "$ZSH_VERSION" ] && [ -n "$SHELL" ] ; then
  _SHELL_NAME=$(basename ${SHELL})
  eval "$($CONDA_EXE shell.$_SHELL_NAME hook)" >/dev/null
	eval "$($MAMBA_EXE shell hook --shell ${_SHELL_NAME})" >/dev/null
fi
