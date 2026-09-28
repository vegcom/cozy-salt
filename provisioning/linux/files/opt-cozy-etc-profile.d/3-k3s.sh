#!/bin/sh
# Managed by Salt - DO NOT EDIT MANUALLY

if ! which kubectl 1>/dev/null 2>/dev/null ; then
	return 2>/dev/null
fi

if which kubecolor 1>/dev/null 2>/dev/null ; then
	alias k=kubecolor
fi
