#!/bin/bash
# Managed by Salt - DO NOT EDIT MANUALLY

# shellcheck  disable=SC1072 disable=SC1073 disable=SC1009 disable=SC1090 disable=SC1091

if [ ! -n "$BASH_VERSION" ]; then
  return 0
fi

if [ -d /etc/profile ]; then
  . /etc/profile
fi

if [ -d /opt/cozy/etc/profile.d ]; then
  for i in $(find /opt/cozy/etc/profile.d/*.sh 2>/dev/null|sort) ; do
    if [ -s "$i" ]; then
      . "$i"
    fi
  done
  unset i
fi

if [ -f /etc/bash.bashrc.machine ]; then
  . /etc/bash.bashrc.machine
fi

case $- in
    *i*) ;;
    *) return 2>/dev/null ;;
esac

if [ "$STARSHIP_DISABLE" != "true" ]; then command -v starship >/dev/null && eval "$(starship init bash)" ; fi
if [ "$CARAPACE_DISABLE" != "true" ]; then command -v carapace >/dev/null && eval "$(carapace _carapace)" ; fi
if [ "$OXIDE_DISABLE" != "true" ]; then command -v zoxide >/dev/null && eval "$(zoxide init bash)" ; fi
if [ "$ATUIN_DISABLE" != "true" ]; then command -v atuin >/dev/null && eval "$(atuin init bash)" ; fi
if [ "$FZF_DISABLE" != "true" ]; then command -v fzf >/dev/null && eval "$(fzf --bash)" ;  fi

command -v tailscale >/dev/null && eval  "$(tailscale completion bash)"
command -v kubecolor >/dev/null && eval  "$(kubecolor completion bash)"
command -v direnv >/dev/null && eval "$(direnv hook bash)"
