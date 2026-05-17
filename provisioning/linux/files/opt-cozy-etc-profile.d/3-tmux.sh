#!/bin/sh
# Managed by Salt - DO NOT EDIT MANUALLY

export TMUX_TMPDIR="${TMPDIR}/tmux"
export TMUX_BASEDIR="${TMUX_TMPDIR}/${UID:-$(id -u)}"

if [ ! -d "${TMUX_BASEDIR}" ]; then
  # shellcheck disable=SC2174
  mkdir -m 0777 -p "${TMUX_BASEDIR}"
fi
