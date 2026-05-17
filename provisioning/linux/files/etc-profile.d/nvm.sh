#!/bin/sh
# Managed by Salt - DO NOT EDIT MANUALLY

# NVM (Node Version Manager) system-wide initialization
# Manages environment for all users to use system-wide /opt/nvm installation
# NPM packages are installed with NPM_CONFIG_PREFIX=/opt/nvm, placing binaries in /opt/nvm/bin



# Set NVM directory
export NVM_DIR="/opt/nvm"

if [ -s "$NVM_DIR/nvm.sh" ]; then
	# shellcheck disable=SC1091
	. "$NVM_DIR/nvm.sh"
fi

if [ -d "$NVM_DIR/bin" ]; then
	export PATH="$NVM_DIR/bin:$PATH"
fi

# Source NVM bash completion if available
if [ -s "$NVM_DIR/bash_completion" ]; then
	# shellcheck disable=SC1091
	. "$NVM_DIR/bash_completion"
fi
