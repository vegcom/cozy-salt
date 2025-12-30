#!/bin/bash
set -e

# Pre-accept minion keys from minions_pre directory
# This ensures test minions are ready immediately without manual acceptance
if [ -d /etc/salt/pki/master/minions_pre ]; then
    echo "=== Pre-accepting minion keys ==="
    for key_file in /etc/salt/pki/master/minions_pre/*.pub; do
        if [ -f "$key_file" ]; then
            minion_id=$(basename "$key_file" .pub)
            minions_dir="/etc/salt/pki/master/minions"
            mkdir -p "$minions_dir"
            cp "$key_file" "$minions_dir/$minion_id"
            echo "  ✓ Pre-accepted $minion_id"
        fi
    done
fi

echo "=== Starting Salt Master ==="
exec salt-master -l info
