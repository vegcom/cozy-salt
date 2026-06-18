#!/bin/sh
# Managed by Salt - DO NOT EDIT MANUALLY

if ! which kubectl 1>/dev/null 2>/dev/null ; then
	return 2>/dev/null
fi


if [ -n "${KUBECONFIG}" ]; then return 2>/dev/null ; fi

if [ -s "${__KUBECONFIG_K3S}" ] && [ -s  "${KUBECONFIG}" ];then
	export KUBECONFIG="${__KUBECONFIG_K3S}:${KUBECONFIG}"
elif [ ! -s "${__KUBECONFIG_K3S}" ] && [ -s  "${KUBECONFIG}" ];then
	export KUBECONFIG="${KUBECONFIG}"
elif [ -s "${__KUBECONFIG_K3S}" ] && [ ! -s  "${KUBECONFIG}" ];then
	export KUBECONFIG="${__KUBECONFIG_K3S}"
fi

if which kubecolor 1>/dev/null 2>/dev/null ; then
	alias k=kubecolor
fi
