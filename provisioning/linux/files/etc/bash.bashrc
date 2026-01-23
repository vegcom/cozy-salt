#!/bin/bash
# Managed by Salt - DO NOT EDIT MANUALLY

if [ -n "${__ETC_PROFILE_SOURCED}" ]; then
    return 0
fi


if [ -d /etc/bash_completion.d/ ] ; then
  # shellcheck disable=SC1091 disable=SC1090
  source /etc/bash_completion.d/*.bash
fi

__ETC_PROFILE_SOURCED=1
export __ETC_PROFILE_SOURCED
