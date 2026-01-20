#!/bin/bash
# Homebrew initialization (default supported path: /home/linuxbrew/.linuxbrew)
# Sets up PATH and shell completions for all users
# Multi-user access managed via cozyusers group with ACL permissions

if [ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi
