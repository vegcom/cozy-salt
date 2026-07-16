#!/bin/sh
# Homebrew initialization (default supported path: /home/linuxbrew/.linuxbrew)
# Sets up PATH and shell completions for all users
# Multi-user access managed via cozyusers group with ACL permissions
# Managed by Salt - DO NOT EDIT MANUALLY



if [ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
		# ref: https://github.com/orgs/Homebrew/discussions/6196
    [ -b "${DISPLAY}" ] && export HOMEBREW_NO_EMOJI=1
		[ -n "${LOREM}" ] && export HOMEBREW_VERBOSE=1
		HOMEBREW_MAKE_JOBS=$(nproc)
fi
