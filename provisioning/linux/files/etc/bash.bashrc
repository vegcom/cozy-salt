#!/bin/bash
# Managed by Salt - DO NOT EDIT MANUALLY

# shellcheck  disable=SC1072 disable=SC1073 disable=SC1009 disable=SC1090 disable=SC1091

if [ ! -n "$BASH_VERSION" ]; then
  return 0
fi

if [ -d /etc/environment ]; then
  . /etc/environment
fi

if [ -d /opt/cozy/etc/environment.d ]; then
  for i in $(find /opt/cozy/etc/environment.d/*.sh 2>/dev/null|sort) ; do
    if [ -r "$i" ]; then
      . "$i"
    fi
  done
  unset i
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

case $- in
    *i*) ;;   # interactive shell
    *) return ;;  # non-interactive shell
esac

if awk '/Ubuntu/ { found=1; exit } END { exit !found }' /etc/os-release ; then
  if [ -d /etc/bash_completion.d/ ] ; then
    . /etc/bash_completion.d/*.bash
  fi
fi


command -v starship >/dev/null && eval "$(starship init bash)"
command -v carapace >/dev/null && eval "$(carapace _carapace)"
command -v zoxide >/dev/null && eval "$(zoxide init bash)"
command -v atuin >/dev/null && eval "$(atuin init bash)"
command -v fzf >/dev/null && eval "$(fzf --bash)"

command -v tailscale >/dev/null && eval  "$(tailscale completion bash)"
command -v kubecolor >/dev/null && eval  "$(kubecolor completion bash)"
command -v direnv >/dev/null && eval "$(direnv hook bash)"
