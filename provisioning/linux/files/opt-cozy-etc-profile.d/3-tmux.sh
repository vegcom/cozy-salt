#!/bin/sh
# Managed by Salt - DO NOT EDIT MANUALLY

export TMUX_TMPDIR="${TMPDIR}/tmux/"

if [ ! -d "${TMUX_TMPDIR}" ]; then
  # shellcheck disable=SC2174
  mkdir -m 0777 -p "${TMUX_TMPDIR}"
fi

# If we're in a persistent session, make sure we use the right socket
if [ -n "$TMUX" ]; then
    export TMUX="$TMUX_SOCKET"
fi

# Helpful aliases
alias t="tmux -L \$TMUX_SOCKET"
alias ta="tmux -L \$TMUX_SOCKET attach"
alias tl="tmux -L \$TMUX_SOCKET list-sessions"
