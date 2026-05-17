#!/bin/sh
# Managed by Salt - DO NOT EDIT MANUALLY

if [ -n "${KUBECONFIG}" ]; then return ; fi

if [ -s "${__KUBECONFIG_K3S}" ] && [ -s  "${KUBECONFIG}" ];then
	export KUBECONFIG="${__KUBECONFIG_K3S}:${KUBECONFIG}"
elif [ ! -s "${__KUBECONFIG_K3S}" ] && [ -s  "${KUBECONFIG}" ];then
	export KUBECONFIG="${KUBECONFIG}"
elif [ -s "${__KUBECONFIG_K3S}" ] && [ ! -s  "${KUBECONFIG}" ];then
	export KUBECONFIG="${__KUBECONFIG_K3S}"
fi
