#!/bin/bash
# NVM (Node Version Manager) system-wide initialization
# Manages environment for all users to use system-wide /opt/nvm installation
# Managed by Salt - DO NOT EDIT MANUALLY

# Set NVM directory
export NVM_DIR="/opt/nvm"
# NOTE: Do NOT export NPM_CONFIG_PREFIX or PREFIX here - NVM rejects these variables
# during installation. These are set only in Salt state environment for npm commands.

# Source NVM if installed
if [ -s "$NVM_DIR/nvm.sh" ]; then
    \. "$NVM_DIR/nvm.sh"  # This loads nvm
fi

# Add global npm packages to PATH
# NPM packages are installed with NPM_CONFIG_PREFIX=/opt/nvm, placing binaries in /opt/nvm/bin
if [ -d "$NVM_DIR/bin" ]; then
    export PATH="$NVM_DIR/bin:$PATH"
fi

# Source NVM bash completion if available
if [ -s "$NVM_DIR/bash_completion" ]; then
    \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
fi
