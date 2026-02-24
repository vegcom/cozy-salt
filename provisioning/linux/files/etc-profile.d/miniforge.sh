#!/bin/bash
# Miniforge conda/mamba initialization (system-wide installation at /opt/miniforge3)
# Available to all users
# Managed by Salt - DO NOT EDIT MANUALLY

CONDA_ROOT_PREFIX='/opt/miniforge3'
CONDA_EXE="${CONDA_ROOT_PREFIX}/bin/conda"

if [ ! -f "$CONDA_EXE" ]; then
    return
fi

if [ -n "$BASH_VERSION" ]; then
    if ! type -f conda &>/dev/null; then
        eval "$(${CONDA_EXE} shell.bash hook)" &>/dev/null
    fi
elif [ -n "$ZSH_VERSION" ]; then
    if ! type -f conda &>/dev/null; then
        eval "$(${CONDA_EXE} shell.zsh hook)" &>/dev/null
    fi
fi
