#!/bin/bash
# Miniforge conda/mamba initialization (system-wide installation at /opt/miniforge3)
# Available to all users
# Managed by Salt - DO NOT EDIT MANUALLY

CONDA_ROOT_PREFIX='/opt/miniforge3'
CONDA_EXE="${CONDA_ROOT_PREFIX}/bin/conda"

if [ ! -f "$CONDA_EXE" ]; then
    return
fi

CONDA_CHANGEPS1=false
export CONDA_CHANGEPS1

if [ -n "$BASH_VERSION" ]; then
    eval "$(${CONDA_EXE} shell.bash hook)" &>/dev/null
elif [ -n "$ZSH_VERSION" ]; then
    eval "$(${CONDA_EXE} shell.zsh hook)" &>/dev/null
fi
