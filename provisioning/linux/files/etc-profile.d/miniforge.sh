#!/bin/bash
# Miniforge conda/mamba initialization (system-wide installation at /opt/miniforge3)
# Available to all users

# >>> conda initialize >>>
__conda_setup="$('/opt/miniforge3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
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
# <<< conda initialize <<<


# >>> mamba initialize >>>
MAMBA_EXE='/opt/miniforge3/bin/mamba'
MAMBA_ROOT_PREFIX='/opt/miniforge3'
export MAMBA_EXE
export MAMBA_ROOT_PREFIX
__mamba_setup="$("$MAMBA_EXE" shell hook --shell bash --root-prefix "$MAMBA_ROOT_PREFIX" 2> /dev/null)"
# shellcheck disable=SC2181
if [ $? -eq 0 ]; then
    eval "${__mamba_setup}"
else
    # shellcheck disable=SC2139
    alias mamba="${MAMBA_EXE}"
fi
unset __mamba_setup

if [ -f "/opt/miniforge3/etc/profile.d/mamba.sh" ]; then
    # shellcheck disable=SC1091
    . "/opt/miniforge3/etc/profile.d/mamba.sh"
fi
# <<< mamba initialize <<<
