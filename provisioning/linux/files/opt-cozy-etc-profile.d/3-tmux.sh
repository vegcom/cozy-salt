#!/bin/sh
# Managed by Salt - DO NOT EDIT MANUALLY

export TMUX_TMPDIR="${TMPDIR}/tmux/"

if [ ! -d "${TMUX_TMPDIR}" ]; then
  # shellcheck disable=SC2174
  mkdir -m 0777 -p "${TMUX_TMPDIR}"
fi
