#!/bin/bash
# Miniforge conda/mamba initialization (system-wide installation at /opt/miniforge3)
# Available to all users
# Managed by Salt - DO NOT EDIT MANUALLY

if [ -n "$BASH_VERSION" ]; then
    __conda_setup="$('/opt/miniforge3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
elif [ -n "$ZSH_VERSION" ]; then
    __conda_setup="$('/opt/miniforge3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
fi

# shellcheck disable=SC2181
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/miniforge3/etc/profile.d/conda.sh" ]; then
        # shellcheck disable=SC1091
        . "/opt/miniforge3/etc/profile.d/conda.sh"
    else
        export PATH="/opt/miniforge3/bin:$PATH"
    fi
fi
unset __conda_setup

MAMBA_ROOT_PREFIX='/opt/miniforge3'
MAMBA_EXE="${MAMBA_ROOT_PREFIX}/bin/mamba"
export MAMBA_EXE
export MAMBA_ROOT_PREFIX

if [ -n "$BASH_VERSION" ]; then
	__mamba_setup="$("$MAMBA_EXE" shell hook --shell bash --root-prefix "$MAMBA_ROOT_PREFIX" 2> /dev/null)"
elif [ -n "$ZSH_VERSION" ]; then
	__mamba_setup="$("$MAMBA_EXE" shell hook --shell zsh --root-prefix "$MAMBA_ROOT_PREFIX" 2> /dev/null)"
fi

# shellcheck disable=SC2181
if [ $? -eq 0 ]; then
    eval "${__mamba_setup}"
else
    # shellcheck disable=SC2139
    alias mamba="${MAMBA_EXE}"
fi
unset __mamba_setup

if [ -n "$BASH_VERSION" ]; then
    eval "$(mamba shell hook --shell bash)"
elif [ -n "$ZSH_VERSION" ]; then
    eval "$(mamba shell hook --shell zsh)"
fi