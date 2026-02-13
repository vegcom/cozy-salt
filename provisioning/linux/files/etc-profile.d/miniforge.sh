#!/bin/bash
# Miniforge conda/mamba initialization (system-wide installation at /opt/miniforge3)
# Available to all users
# Managed by Salt - DO NOT EDIT MANUALLY

MAMBA_ROOT_PREFIX='/opt/miniforge3'
MAMBA_EXE="${MAMBA_ROOT_PREFIX}/bin/mamba"
CONDA_ROOT_PREFIX='/opt/miniforge3'
CONDA_EXE="${CONDA_ROOT_PREFIX}/bin/conda"

export MAMBA_EXE CONDA_EXE MAMBA_ROOT_PREFIX CONDA_ROOT_PREFIX

# shellcheck disable=SC2139
alias mamba="${MAMBA_EXE}"
# shellcheck disable=SC2139
alias conda="${CONDA_EXE}"

if [ -n "$BASH_VERSION" ]; then
    eval "$(conda shell.bash hook)"
elif [ -n "$ZSH_VERSION" ]; then
    eval "$(conda shell.zsh hook)"
fi
