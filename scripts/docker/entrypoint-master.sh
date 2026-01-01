#!/bin/bash
set -e

# Pre-accept minion keys from build-time generated keys
# Keys are baked into image at /etc/salt/pki/master/minions-preload/
# This ensures test minions are ready immediately without manual acceptance
preload_dir="/etc/salt/pki/master/minions-preload"
minions_dir="/etc/salt/pki/master/minions"

if [ -d "$preload_dir" ]; then
    echo "=== Pre-accepting minion keys ==="
    mkdir -p "$minions_dir"
    for key_file in "$preload_dir"/*.pub; do
        if [ -f "$key_file" ]; then
            minion_id=$(basename "$key_file" .pub)
            # Only copy if not already accepted (preserves any runtime key changes)
            if [ ! -f "$minions_dir/$minion_id" ]; then
                cp "$key_file" "$minions_dir/$minion_id"
                echo "  + Pre-accepted $minion_id"
            else
                echo "  - $minion_id already accepted"
            fi
        fi
    done
fi

echo "=== Starting Salt Master ==="
exec salt-master -l info
