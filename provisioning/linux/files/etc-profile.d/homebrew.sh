# Homebrew initialization for Linux
# Sets up PATH and shell completions if ~/.linuxbrew is installed

if [ -d "$HOME/.linuxbrew" ]; then
    eval "$($HOME/.linuxbrew/bin/brew shellenv)"
fi
