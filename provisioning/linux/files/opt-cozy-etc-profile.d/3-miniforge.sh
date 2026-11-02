#!/bin/sh
# Managed by Salt - DO NOT EDIT MANUALLY

# shellcheck disable=SC2046 disable=SC2086 disable=SC3028

export CONDA_PKGS_BASE="${TMPDIR}/cache/miniforge"
export CONDA_PKGS_DIRS="${CONDA_PKGS_BASE}/${UID:-$(id -u)}"
export CONDA_BASE_PATH="${CONDA_BASE_PATH:-/opt/miniforge3/bin}"
export CONDA_EXE="$CONDA_BASE_PATH/conda"
export MAMBA_EXE="$CONDA_BASE_PATH/mamba"

if [ ! -n "${SHELL}" ]; then
	if [ -x /bin/zsh ]; then
		SHELL=$/bin/zsh
	elif [ -x /bin/bash ]; then
		SHELL=$/bin/bash
  else
    return 1 2>/dev/null || exit 1
	fi
fi

if [ -n "$BASH_VERSION" ] || [ -n "$ZSH_VERSION" ]; then
	_SHELL_NAME="$(basename ${SHELL})"
	eval "$($CONDA_BASE_PATH/conda shell.$_SHELL_NAME hook)" >/dev/null
	eval "$($CONDA_BASE_PATH/mamba shell hook --shell ${_SHELL_NAME})" >/dev/null
fi

if [ -f "${CONDA_BASE_PATH}/conda" ]; then
	${CONDA_BASE_PATH}/conda config --remove envs_dirs "/home/${USER}/.conda/envs" >/dev/null 2>&1 || true
fi
