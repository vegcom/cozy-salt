#!/bin/sh
# Managed by Salt - DO NOT EDIT MANUALLY

if [ -d /etc/bash_completion.d/ ] ; then
	# shellcheck disable=SC1090
	. /etc/bash_completion.d/*.bash 2>/dev/null
fi
