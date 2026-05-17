#!/bin/bash
# Managed by Salt - DO NOT EDIT MANUALLY

if [ ! -n "$BASH_VERSION" ]; then
	return 0
fi

# shellcheck disable=SC1009
if [ -d /etc/profile.d ]; then
  # shellcheck  disable=SC1072 disable=SC1073
  for i in $(find /etc/profile.d/*.sh 2>/dev/null|sort) ; do
    if [ -r "$i" ]; then
      # shellcheck disable=SC1090
      . "$i"
    fi
  done
  unset i
fi

command -v direnv >/dev/null && eval "$(direnv hook bash)"
command -v carapace >/dev/null && eval "$(carapace _carapace)"
command -v zoxide >/dev/null && eval "$(zoxide init bash)"
command -v starship >/dev/null && eval "$(starship init bash)"
command -v atuin >/dev/null && eval "$(atuin init bash)"
command -v fzf >/dev/null && eval "$(fzf --bash)"
command -v tailscale >/dev/null && eval  "$(tailscale completion bash)"
command -v kubecolor >/dev/null && eval  "$(kubecolor completion bash)"
