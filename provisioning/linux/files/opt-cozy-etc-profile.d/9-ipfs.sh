#!/bin/sh
# Managed by Salt - DO NOT EDIT MANUALLY

# shellcheck disable=SC3028
if [ "${EUID:-$(id -u)}" -ne 0 ] && [ ! -b "${SUDO_USER}" ]; then
	if [ -f /opt/kubo/ipfs ]; then
		alias ipfs="sudo -E /opt/kubo/ipfs"
	fi
fi

export PATH="/opt/kubo:$PATH"
export IPFS_PATH="/opt/cozy/etc/kubo"
