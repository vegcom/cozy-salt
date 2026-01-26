#!/bin/bash
# Managed by Salt - DO NOT EDIT MANUALLY

if [ -n "${__ETC_BASHRC_SOURCED}" ]; then
    return 0
fi

# FIXME: this doesn't actually work well on archlinux presently,
#   some stub work in /etc-profile.d/0-functions.sh
if  ! awk '/Arch/ { found=1; exit } END { exit !found }' /etc/os-release ; then
  if [ -d /etc/bash_completion.d/ ] ; then
    # shellcheck disable=SC1091 disable=SC1090
    source /etc/bash_completion.d/*.bash
  fi
fi

__ETC_BASHRC_SOURCED=1
export __ETC_BASHRC_SOURCED
