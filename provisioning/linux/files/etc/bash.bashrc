#!/bin/bash
# Managed by Salt - DO NOT EDIT MANUALLY


if awk '/Ubuntu/ { found=1; exit } END { exit !found }' /etc/os-release ; then
  if [ -d /etc/bash_completion.d/ ] ; then
    # shellcheck disable=SC1091 disable=SC1090
    . /etc/bash_completion.d/*.bash
  fi
fi

command -v carapace >/dev/null && eval "$(carapace _carapace)"
command -v zoxide >/dev/null && eval "$(zoxide init bash)"
command -v starship >/dev/null && eval "$(starship init bash)"
command -v atuin >/dev/null && eval "$(atuin init bash)"
