#!/bin/sh
# Managed by Salt - DO NOT EDIT MANUALLY

if [ -n "$XDG_RUNTIME_DIR" ]; then
	export XDG_RUNTIME_DIR="/run/user/$(id -u)"
fi

if [ -n "$DBUS_SESSION_BUS_ADDRESS" ]; then
	export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus
fi
