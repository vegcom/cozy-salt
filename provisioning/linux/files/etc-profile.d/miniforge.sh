# Miniforge conda initialization
# Automatically initialize conda if ~/.miniforge3 exists

if [ -f "$HOME/.miniforge3/etc/profile.d/conda.sh" ]; then
    __conda_setup="$("$HOME/.miniforge3/bin/conda" shell.bash hook 2> /dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__conda_setup"
    else
        export PATH="$HOME/.miniforge3/bin:$PATH"
    fi
    unset __conda_setup
fi
