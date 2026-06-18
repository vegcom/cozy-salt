#!/bin/sh
# Managed by Salt - DO NOT EDIT MANUALLY

# shellcheck disable=SC2046 disable=SC2086 disable=SC3028

export CONDA_PKGS_BASE="${TMPDIR}/cache/miniforge"
export CONDA_PKGS_DIRS="${CONDA_PKGS_BASE}/${UID:-$(id -u)}"

export CONDA_BASE_PATH="${CONDA_BASE_PATH:-/opt/miniforge3/bin/}"

if [ -n "$BASH_VERSION" ] || [ -n "$ZSH_VERSION" ] && [ -n "$SHELL" ] ; then
  _SHELL_NAME="$(basename ${SHELL})"
  eval "$($CONDA_BASE_PATH/conda shell.$_SHELL_NAME hook)" >/dev/null
	eval "$($CONDA_BASE_PATH/mamba shell hook --shell ${_SHELL_NAME})" >/dev/null
fi
