#!/bin/sh
# Managed by Salt - DO NOT EDIT MANUALLY

export PIP_CACHE_BASE="${TMPDIR}/pip-cache"
export PIP_CACHE_DIR="${PIP_CACHE_BASE}/${UID:-$(id -u)}"
