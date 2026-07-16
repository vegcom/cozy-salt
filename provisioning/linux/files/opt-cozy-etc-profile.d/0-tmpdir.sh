#!/bin/sh
# Managed by Salt - DO NOT EDIT MANUALLY

if [ -n "${_TMPDIR}" ]; then
	export TMPDIR="${_TMPDIR}"
	export USER_TMPDIR="${_TMPDIR}"
else
	export TMPDIR="/tmp"
fi
