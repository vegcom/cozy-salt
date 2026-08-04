#!/bin/sh
# Managed by Salt - DO NOT EDIT MANUALLY

# shellcheck disable=SC3028
if [ "${EUID:-$(id -u)}" -ne 0 ] && [ ! -b "${SUDO_USER}" ]; then
	if [ -f /opt/saltstack/salt/salt-call ]; then
		alias salt-call="sudo -E /opt/saltstack/salt/salt-call"
	fi
fi

if docker ps -a --format='{{.Names}}' --filter='name=salt' 2>/dev/null | grep -Pqe 'salt' ; then
	alias salt="docker exec -it salt salt"
	alias salt-key='docker exec -it salt salt-key'
	alias salt-run='docker exec -it salt salt-run'
	alias salt-ssh='docker exec -it salt salt'
fi

if [ ! -s /etc/bash_completion.d/salt.bash ]; then
	if [ "${EUID:-$(id -u)}" -eq 0 ] ; then
		wget -O /etc/bash_completion.d/salt.bash https://raw.githubusercontent.com/saltstack/salt/develop/pkg/salt.bash
	fi
fi

if [ -s /etc/bash_completion.d/salt.bash ] ; then
	if [ ! -n "$BASH_VERSION" ]; then
		return 2>/dev/null
	fi
	# shellcheck disable=SC1091
	. /etc/bash_completion.d/salt.bash
fi

export PATH="/opt/saltstack/salt:$PATH"
