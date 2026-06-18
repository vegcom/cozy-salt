#!/bin/sh
# Managed by Salt - DO NOT EDIT MANUALLY

if [ -f /home/linuxbrew/.linuxbrew/bin/brew ]; then
	alias brew="sudo -u cozy-salt-svc /home/linuxbrew/.linuxbrew/bin/brew"
fi
