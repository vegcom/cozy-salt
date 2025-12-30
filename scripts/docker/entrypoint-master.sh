#!/bin/bash
set -e

# Configure auto_accept based on environment variable
# SALT_AUTO_ACCEPT: true (default for testing), false (production)
AUTO_ACCEPT=${SALT_AUTO_ACCEPT:-true}

# Remove existing auto_accept.conf to avoid duplicates
rm -f /etc/salt/master.d/auto_accept.conf

if [ "$AUTO_ACCEPT" = "true" ]; then
    cat > /etc/salt/master.d/auto_accept.conf <<EOF
# Auto-accept minion keys (for testing/trusted networks only)
auto_accept: True
EOF
    echo "=== Salt Master: auto_accept enabled (testing mode) ==="
else
    cat > /etc/salt/master.d/auto_accept.conf <<EOF
# Auto-accept disabled (production mode)
auto_accept: False
EOF
    echo "=== Salt Master: auto_accept disabled (production mode) ==="
fi

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
