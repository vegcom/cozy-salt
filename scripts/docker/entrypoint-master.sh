#!/bin/bash
set -e

# Generate master keys if they don't exist (CI environment)
# Local dev bind-mounts keys from host, so this only runs in CI
master_pki="/etc/salt/pki/master"
if [ ! -f "$master_pki/master.pem" ]; then
    echo "=== Generating master keys ==="
    mkdir -p "$master_pki"
    openssl genrsa -out "$master_pki/master.pem" 4096 2>/dev/null
    openssl rsa -in "$master_pki/master.pem" -pubout -out "$master_pki/master.pub" 2>/dev/null
    chmod 600 "$master_pki/master.pem"
    chmod 644 "$master_pki/master.pub"
    chown -R salt:salt "$master_pki"
    echo "  + Generated master.pem and master.pub"
fi

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
