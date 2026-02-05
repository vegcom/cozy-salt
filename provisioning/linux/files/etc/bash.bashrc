#!/bin/bash
# Managed by Salt - DO NOT EDIT MANUALLY

if [ -n "${__ETC_BASHRC_SOURCED}" ]; then
    return 0
fi

# FIXME: this doesn't actually work well on archlinux presently,
#   some stub work in /etc-profile.d/0-functions.sh
#   Presently we _THINK_ it works on ubuntu, but i forgot ngl
if awk '/Ubuntu/ { found=1; exit } END { exit !found }' /etc/os-release ; then
  if [ -d /etc/bash_completion.d/ ] ; then
    # shellcheck disable=SC1091 disable=SC1090
    source /etc/bash_completion.d/*.bash
  fi
fi

command -v carapace >/dev/null && eval "$(carapace _carapace)"
command -v zoxide >/dev/null && eval "$(zoxide init bash)"
command -v starship >/dev/null && eval "$(starship init bash)"
command -v atuin >/dev/null && eval "$(atuin init bash)"

__ETC_BASHRC_SOURCED=1
export __ETC_BASHRC_SOURCED
