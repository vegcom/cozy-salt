#!/bin/sh
# Managed by Salt - DO NOT EDIT MANUALLY

# shellcheck disable=SC3028
# shellcheck disable=SC2174

export TMUX_TMPDIR="${TMPDIR}/tmux"
export TMUX_BASE_PATH="${TMUX_TMPDIR}/tmux-${EUID:-$(id -u)}"
export TMUX_SOCKET="${TMUX_SOCKET:-default}"

if [ ! -d "${TMUX_TMPDIR}" ]; then
  mkdir -m 0777 -p "${TMUX_TMPDIR}"
	mkdir -m 0700 "${TMUX_BASE_PATH}"
fi

# If we're in a persistent session, make sure we use the right socket
if [ -n "$TMUX" ]; then
    export TMUX_SOCKET="$TMUX_SOCKET"
fi

# Helpful aliases
alias t="tmux -L \$TMUX_SOCKET"
alias ta="tmux -L \$TMUX_SOCKET attach"
alias tl="tmux -L \$TMUX_SOCKET list-sessions"
