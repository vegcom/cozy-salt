#!/bin/bash
# Managed by Salt - DO NOT EDIT MANUALLY

if [ -f /etc/profile ] ; then
  # shellcheck disable=SC1091
  source /etc/profile
fi

if [ -d /etc/bash_completion.d/ ] ; then
  # shellcheck disable=SC1091 disable=SC1090
  source /etc/bash_completion.d/*.bash
fi
